import SwiftUI

/// Placeholder until v0.4 brings live MapKit integration.
struct MapPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 12) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    Text("Family Map")
                        .font(.title2.bold())
                    Text("Live location sharing — coming in v0.4")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("Map")
        }
    }
}
