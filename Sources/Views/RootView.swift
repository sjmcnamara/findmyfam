import SwiftUI

struct RootView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        TabView {
            FamilyMapView(viewModel: appViewModel.locationViewModel)
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }

            chatTab
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .alert("Approve Member?", isPresented: approvalBinding) {
            Button("Approve") { Task { await appViewModel.approvePendingMember() } }
            Button("Dismiss", role: .cancel) { appViewModel.pendingApproval = nil }
        } message: {
            if let approval = appViewModel.pendingApproval {
                let groupName = appViewModel.groupListViewModel?.groups
                    .first(where: { $0.id == approval.groupId })?.name ?? "a group"
                Text("\(String(approval.pubkeyHex.prefix(8)))… wants to join \(groupName).")
            }
        }
    }

    private var approvalBinding: Binding<Bool> {
        Binding(
            get: { appViewModel.pendingApproval != nil },
            set: { if !$0 { appViewModel.pendingApproval = nil } }
        )
    }

    @ViewBuilder
    private var chatTab: some View {
        if let groupListVM = appViewModel.groupListViewModel {
            GroupListView(viewModel: groupListVM)
        } else {
            // Marmot not yet initialised — show placeholder
            VStack(spacing: 12) {
                ProgressView()
                Text("Connecting…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
