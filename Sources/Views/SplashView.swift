import SwiftUI

/// Full-screen launch screen shown while the app connects to relays
/// and initialises the MLS encryption layer.
///
/// Dismissed automatically when `AppViewModel.startupPhase == .ready`.
struct SplashView: View {

    let phase: AppViewModel.StartupPhase

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image("WhistleLogo")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.main.bounds.width * 0.55)
                    .foregroundStyle(.primary)

                Spacer()

                VStack(spacing: 14) {
                    ProgressView()
                        .tint(.secondary)
                        .scaleEffect(1.1)

                    Text(phase.message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: phase.message)
                }
                .padding(.bottom, 56)
            }
        }
    }
}
