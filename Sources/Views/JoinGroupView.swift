import SwiftUI

/// Sheet for joining a group via invite code.
/// Accepts a code via: paste, QR scan, nearby share, or deep link pre-fill.
struct JoinGroupView: View {
    @ObservedObject var viewModel: GroupListViewModel
    var initialCode: String?
    /// The current user's pubkey hex — used to build the approval-request URL after joining.
    var myPubkeyHex: String?
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode = ""
    @State private var isJoining = false
    @State private var error: String?
    @State private var didJoin = false
    @State private var showScanner = false
    @State private var showNearbyShare = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Invite Code", text: $inviteCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.body.monospaced())
                } footer: {
                    Text("Paste a code, scan a QR code, or tap an NFC tag.")
                }

                // Quick-action buttons
                Section {
                    Button {
                        showNearbyShare = true
                    } label: {
                        Label("Join Nearby", systemImage: "wave.3.left.circle.fill")
                    }

                    Button {
                        showScanner = true
                    } label: {
                        Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                    }
                }

                if didJoin {
                    Section {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Key package published. Now share your key with the group admin so they can approve you.")
                                .font(.caption)
                        }
                    }

                    if let approvalURL = approvalURL() {
                        Section {
                            ShareLink(item: approvalURL) {
                                Label("Share my key with the admin", systemImage: "person.badge.key.fill")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } footer: {
                            Text("Send this to the group admin via AirDrop, Messages, etc. They tap it once to approve you — no copy-paste needed.")
                        }
                    }
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Join Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if didJoin {
                        Button("Done") { dismiss() }
                    } else {
                        Button("Join") {
                            Task { await joinGroup() }
                        }
                        .disabled(inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isJoining)
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                NavigationStack {
                    QRScannerView { scanned in
                        inviteCode = extractCode(from: scanned)
                        showScanner = false
                        Task { await joinGroup() }
                    }
                    .navigationTitle("Scan QR Code")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .onAppear {
                if let code = initialCode, !code.isEmpty {
                    inviteCode = code
                }
            }
            .sheet(isPresented: $showNearbyShare) {
                NearbyShareView(role: .browser) { received in
                    inviteCode = extractCode(from: received)
                    Task { await joinGroup() }
                }
            }
        }
    }

    /// Build the `famstr://addmember/` URL to share with the group admin for one-tap approval.
    private func approvalURL() -> URL? {
        guard let pubkey = myPubkeyHex else { return nil }
        // Decode the group ID from the accepted invite code
        let rawCode = extractCode(from: inviteCode)
        guard let groupId = try? InviteCode.decode(from: rawCode).groupId else { return nil }
        return InviteCode.approvalURL(pubkeyHex: pubkey, groupId: groupId)
    }

    /// Extract the raw base64 invite code from either a `famstr://` URL or a raw string.
    private func extractCode(from scanned: String) -> String {
        guard let url = URL(string: scanned),
              url.scheme == "famstr",
              url.host == "invite",
              let code = url.pathComponents.dropFirst().first else {
            return scanned
        }
        return code
    }

    private func joinGroup() async {
        let code = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        isJoining = true
        defer { isJoining = false }

        do {
            try await viewModel.joinGroup(inviteCode: code)
            didJoin = true
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
