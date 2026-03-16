import Foundation

/// Configuration for a single Nostr relay.
struct RelayConfig: Identifiable, Codable, Hashable {
    let id: UUID
    var url: String
    var isEnabled: Bool

    init(url: String, isEnabled: Bool = true) {
        self.id = UUID()
        self.url = url
        self.isEnabled = isEnabled
    }
}
