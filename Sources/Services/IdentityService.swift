import Foundation
import NostrSDK

/// Manages the user's Nostr identity.
///
/// On first launch a new keypair is generated and the nsec is stored via `storage`.
/// On subsequent launches the nsec is restored and the `Keys` object reconstructed.
/// The nsec is never exposed outside this class.
@MainActor
final class IdentityService: ObservableObject {

    /// The displayable (public-only) identity. Nil only transiently during init.
    @Published private(set) var identity: NostrIdentity?

    /// True when this is the first time the app has run on this device.
    @Published private(set) var isNewUser = false

    /// The live nostr-sdk-swift Keys object used to sign events.
    /// Accessed by RelayService; never exposed further up the stack.
    private(set) var keys: Keys?

    // MARK: - Init

    /// - Parameter storage: Injected key storage (defaults to Keychain for production).
    init(storage: SecureStorage = KeychainService.shared) {
        self.storage = storage
        loadOrCreate()
    }

    // MARK: - Private

    private let storage: SecureStorage

    private func loadOrCreate() {
        if let nsec = storage.load(key: .nsec) {
            restoreKeys(from: nsec)
        } else {
            createNewIdentity()
        }
    }

    private func restoreKeys(from nsec: String) {
        do {
            let restored = try Keys.parse(secretKey: nsec)
            let npub     = try restored.publicKey().toBech32()
            let pubHex   = restored.publicKey().toHex()

            self.keys      = restored
            self.identity  = NostrIdentity(npub: npub, publicKeyHex: pubHex)
            self.isNewUser = false

            FMFLogger.identity.info("Identity restored: \(npub)")
        } catch {
            FMFLogger.identity.error("Failed to restore keys, generating new ones: \(error)")
            createNewIdentity()
        }
    }

    private func createNewIdentity() {
        let newKeys = Keys.generate()
        do {
            let nsec   = try newKeys.secretKey().toBech32()
            let npub   = try newKeys.publicKey().toBech32()
            let pubHex = newKeys.publicKey().toHex()

            storage.save(key: .nsec, value: nsec)

            self.keys      = newKeys
            self.identity  = NostrIdentity(npub: npub, publicKeyHex: pubHex)
            self.isNewUser = true

            FMFLogger.identity.info("New identity created: \(npub)")
        } catch {
            FMFLogger.identity.error("Fatal: could not create identity: \(error)")
        }
    }
}
