import Foundation
import Combine
import MDKBindings
import NostrSDK

/// Drives the group detail / management view — member list, invite, remove.
@MainActor
final class GroupDetailViewModel: ObservableObject {

    // MARK: - Published state

    @Published private(set) var groupName: String = ""
    @Published private(set) var members: [MemberItem] = []
    @Published private(set) var inviteCode: String?
    @Published private(set) var isLoading = false
    @Published private(set) var isAddingMember = false
    @Published private(set) var didAddMember = false
    @Published private(set) var error: String?
    @Published var addMemberNpub: String = ""

    // MARK: - Item model

    struct MemberItem: Identifiable, Equatable {
        let id: String           // pubkeyHex
        let pubkeyHex: String
        let displayName: String
        let isAdmin: Bool
        let isMe: Bool
    }

    // MARK: - Dependencies

    let groupId: String
    private let marmot: MarmotService
    private let mls: MLSService
    private let nicknameStore: NicknameStore
    private let myPubkeyHex: String
    private var cancellable: AnyCancellable?

    // MARK: - Init

    init(
        groupId: String,
        marmot: MarmotService,
        mls: MLSService,
        nicknameStore: NicknameStore,
        myPubkeyHex: String
    ) {
        self.groupId = groupId
        self.marmot = marmot
        self.mls = mls
        self.nicknameStore = nicknameStore
        self.myPubkeyHex = myPubkeyHex

        // Re-resolve display names when nicknames change
        cancellable = nicknameStore.$nicknames
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshDisplayNames()
            }
    }

    // MARK: - Load

    /// Fetch group metadata and member list from MDK.
    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load group metadata
            if let group = try await mls.getGroup(mlsGroupId: groupId) {
                groupName = group.name.isEmpty ? "Unnamed Group" : group.name
            }

            // Load member pubkeys and admin list
            let memberPubkeys = try await mls.getMembers(groupId: groupId)
            let group = try await mls.getGroup(mlsGroupId: groupId)
            let adminPubkeys = Set(group?.adminPubkeys ?? [])

            members = memberPubkeys.map { pubkey in
                MemberItem(
                    id: pubkey,
                    pubkeyHex: pubkey,
                    displayName: nicknameStore.displayName(for: pubkey),
                    isAdmin: adminPubkeys.contains(pubkey),
                    isMe: pubkey == myPubkeyHex
                )
            }.sorted { lhs, rhs in
                // Sort: me first, then admins, then alphabetical
                if lhs.isMe != rhs.isMe { return lhs.isMe }
                if lhs.isAdmin != rhs.isAdmin { return lhs.isAdmin }
                return lhs.displayName < rhs.displayName
            }

            error = nil
        } catch {
            self.error = error.localizedDescription
            FMFLogger.chat.error("Failed to load group detail for \(self.groupId): \(error)")
        }
    }

    // MARK: - Invite

    /// Generate a shareable invite code for this group.
    func generateInvite() {
        do {
            let relays = marmot.activeRelayURLs
            guard let relay = relays.first else {
                error = "No connected relays"
                return
            }
            inviteCode = try marmot.generateInviteCode(for: groupId, relay: relay)
            error = nil
        } catch {
            self.error = error.localizedDescription
            FMFLogger.chat.error("Failed to generate invite: \(error)")
        }
    }

    // MARK: - Add member

    /// Add a member to the group by their npub or hex pubkey.
    ///
    /// The invitee must have already published a key package (via acceptInvite).
    /// This fetches their key package from relays and performs the MLS add.
    func addMember() async {
        let input = addMemberNpub.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }

        isAddingMember = true
        defer { isAddingMember = false }

        do {
            // Resolve npub → hex if needed
            let pubkeyHex: String
            if input.hasPrefix("npub") {
                let pk = try NostrSDK.PublicKey.parse(publicKey: input)
                pubkeyHex = pk.toHex()
            } else {
                pubkeyHex = input
            }

            try await marmot.addMember(publicKeyHex: pubkeyHex, toGroup: groupId)
            addMemberNpub = ""
            error = nil

            // Reload member list
            await load()
            FMFLogger.chat.info("Added member \(pubkeyHex.prefix(8)) to group \(self.groupId)")

            // Signal the view to dismiss back to the chat
            didAddMember = true
        } catch {
            self.error = error.localizedDescription
            FMFLogger.chat.error("Failed to add member: \(error)")
        }
    }

    // MARK: - Remove member

    /// Remove a member from the group. Only admins can do this.
    func removeMember(pubkeyHex: String) async {
        do {
            let result = try await mls.removeMembers(
                groupId: groupId,
                memberPublicKeys: [pubkeyHex]
            )
            try await mls.mergePendingCommit(groupId: groupId)

            // Publish the evolution event
            let payload = result.publishPayload(relayURLs: marmot.activeRelayURLs)
            for eventJson in payload.events {
                try await marmot.publishGroupEvent(eventJson: eventJson)
            }

            // Reload member list
            await load()
            FMFLogger.chat.info("Removed member \(pubkeyHex.prefix(8)) from group \(self.groupId)")
        } catch {
            self.error = error.localizedDescription
            FMFLogger.chat.error("Failed to remove member: \(error)")
        }
    }

    /// Whether the current user is an admin of this group.
    var isAdmin: Bool {
        members.first(where: \.isMe)?.isAdmin ?? false
    }

    // MARK: - Nickname refresh

    /// Re-resolve display names in-place when NicknameStore changes.
    private func refreshDisplayNames() {
        members = members.map { m in
            MemberItem(
                id: m.id,
                pubkeyHex: m.pubkeyHex,
                displayName: nicknameStore.displayName(for: m.pubkeyHex),
                isAdmin: m.isAdmin,
                isMe: m.isMe
            )
        }
    }
}
