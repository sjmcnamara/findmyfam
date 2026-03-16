import Foundation
import NostrSDK

/// Manages connections to Nostr relays.
///
/// Phase 1: connect/disconnect, expose connection state.
/// Phase 3: publish kind 443/444/445 events for Marmot group traffic.
@MainActor
final class RelayService: ObservableObject {

    // MARK: - Connection state

    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case failed(String)
    }

    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var connectedRelayURLs: [String] = []

    // MARK: - Private

    private var client: Client?

    // MARK: - Public API

    /// Connect to the given relays using the provided signing keys.
    func connect(keys: Keys, relays: [RelayConfig]) async {
        guard !relays.isEmpty else {
            FMFLogger.relay.warning("No relays configured — skipping connect")
            return
        }

        connectionState = .connecting

        let signer    = NostrSigner.keys(keys: keys)
        let newClient = Client(signer: signer)
        var added: [String] = []

        for relay in relays where relay.isEnabled {
            do {
                let url = try RelayUrl.parse(url: relay.url)
                _ = try await newClient.addRelay(url: url)
                added.append(relay.url)
                FMFLogger.relay.debug("Added relay: \(relay.url)")
            } catch {
                FMFLogger.relay.warning("Skipping relay \(relay.url): \(error)")
            }
        }

        await newClient.connect()

        self.client            = newClient
        self.connectedRelayURLs = added
        self.connectionState   = added.isEmpty ? .failed("No relays connected") : .connected

        FMFLogger.relay.info("Connected to \(added.count) relay(s)")
    }

    /// Disconnect from all relays.
    func disconnect() async {
        await client?.disconnect()
        client             = nil
        connectedRelayURLs = []
        connectionState    = .disconnected
        FMFLogger.relay.info("Disconnected from all relays")
    }

    /// Publish a pre-built event to all connected relays.
    /// - Returns: The event ID on success.
    @discardableResult
    func publish(builder: EventBuilder) async throws -> String {
        guard let client else {
            throw RelayError.notConnected
        }
        let output = try await client.sendEventBuilder(builder: builder)
        return try output.id.toBech32()
    }

    // MARK: - Errors

    enum RelayError: LocalizedError {
        case notConnected

        var errorDescription: String? {
            switch self {
            case .notConnected: return "Not connected to any relay"
            }
        }
    }
}
