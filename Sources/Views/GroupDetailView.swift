import SwiftUI

/// Group management view — member list, invite generation, and admin actions.
struct GroupDetailView: View {
    @ObservedObject var viewModel: GroupDetailViewModel
    @State private var showInvite = false

    var body: some View {
        List {
            // MARK: - Group info
            Section("Group") {
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundStyle(.blue)
                    Text(viewModel.groupName)
                        .font(.headline)
                }
            }

            // MARK: - Members
            Section("Members (\(viewModel.members.count))") {
                ForEach(viewModel.members) { member in
                    memberRow(member)
                }
                .onDelete { offsets in
                    Task { await deleteMember(at: offsets) }
                }
            }

            // MARK: - Add member (admin only)
            if viewModel.isAdmin {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Member")
                            .font(.subheadline.bold())
                        Text("Paste the npub or hex pubkey of someone who has accepted your invite.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            TextField("npub1… or hex", text: $viewModel.addMemberNpub)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.body.monospaced())

                            Button {
                                Task { await viewModel.addMember() }
                            } label: {
                                if viewModel.isAddingMember {
                                    ProgressView()
                                } else {
                                    Text("Add")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(
                                viewModel.addMemberNpub.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                || viewModel.isAddingMember
                            )
                        }
                    }
                    .padding(.vertical, 4)
                } footer: {
                    Text("The member must publish a key package first (by accepting the invite code).")
                }
            }

            // MARK: - Invite
            Section {
                Button {
                    viewModel.generateInvite()
                    showInvite = true
                } label: {
                    Label("Generate Invite Code", systemImage: "person.badge.plus")
                }
            }

            if let error = viewModel.error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Group Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showInvite) {
            if let code = viewModel.inviteCode {
                InviteShareView(inviteCode: code)
            }
        }
        .deleteDisabled(!viewModel.isAdmin)
    }

    // MARK: - Member row

    private func memberRow(_ member: GroupDetailViewModel.MemberItem) -> some View {
        HStack {
            Image(systemName: member.isMe ? "person.crop.circle.fill" : "person.circle")
                .foregroundStyle(member.isMe ? .blue : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(member.displayName)
                        .font(.body)
                    if member.isMe {
                        Text("(You)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if member.isAdmin {
                    Text("Admin")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            Spacer()
        }
    }

    // MARK: - Delete

    private func deleteMember(at offsets: IndexSet) async {
        for index in offsets {
            let member = viewModel.members[index]
            guard !member.isMe else { continue }
            await viewModel.removeMember(pubkeyHex: member.pubkeyHex)
        }
    }
}
