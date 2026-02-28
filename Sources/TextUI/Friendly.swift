/// A convenience typealias combining the most commonly needed protocols.
///
/// Types conforming to `Friendly` can be serialized, compared, hashed,
/// and safely shared across concurrency domains.
public typealias Friendly = Codable & Equatable & Hashable & Sendable
