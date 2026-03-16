import Foundation

/// Root view-model. Owns the core services and coordinates startup.
@MainActor
final class AppViewModel: ObservableObject {

    let identity: IdentityService
    let relay: RelayService
    let settings: AppSettings

    init() {
        self.identity = IdentityService()
        self.relay    = RelayService()
        self.settings = AppSettings.shared
    }

    /// Called once when the app becomes active.
    func onAppear() async {
        guard let keys = identity.keys else {
            FMFLogger.relay.error("No identity available — cannot connect to relays")
            return
        }
        let enabled = settings.relays.filter(\.isEnabled)
        await relay.connect(keys: keys, relays: enabled)
    }
}
