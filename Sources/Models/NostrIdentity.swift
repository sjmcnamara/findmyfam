import Foundation

/// The user's Nostr identity — public-facing only.
/// The private key (nsec) lives exclusively in the Keychain, accessed via IdentityService.
struct NostrIdentity: Equatable {
    /// Full bech32-encoded public key: "npub1..."
    let npub: String
    /// Raw hex public key (for internal Nostr event authoring)
    let publicKeyHex: String

    /// Abbreviated form for UI display: "npub1abc...xyz"
    var shortNpub: String {
        guard npub.count > 16 else { return npub }
        return "\(npub.prefix(10))...\(npub.suffix(6))"
    }
}
