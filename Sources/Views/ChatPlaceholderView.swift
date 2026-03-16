import SwiftUI

/// Placeholder until v0.5 brings encrypted group chat.
struct ChatPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    Text("Family Chat")
                        .font(.title2.bold())
                    Text("End-to-end encrypted group chat — coming in v0.5")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("Chat")
        }
    }
}
