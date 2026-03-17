import SwiftUI

@main
struct FindMyFamApp: App {

    @StateObject private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appViewModel)
                .task {
                    await appViewModel.onAppear()
                }
                .onOpenURL { url in
                    appViewModel.handleIncomingURL(url)
                }
        }
    }
}
