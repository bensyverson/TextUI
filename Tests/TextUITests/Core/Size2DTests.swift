import Foundation
import Testing
@testable import TextUI

@MainActor
@Suite("Size2D")
struct Size2DTests {
    @Test("Initializes with width and height")
    func initWidthHeight() {
        let size = Size2D(width: 10, height: 5)
        #expect(size.width == 10)
        #expect(size.height == 5)
    }

    @Test("Zero constant is (0, 0)")
    func zero() {
        #expect(Size2D.zero.width == 0)
        #expect(Size2D.zero.height == 0)
    }

    @Test("Equatable compares both dimensions")
    func equatable() {
        #expect(Size2D(width: 3, height: 4) == Size2D(width: 3, height: 4))
        #expect(Size2D(width: 3, height: 4) != Size2D(width: 3, height: 5))
        #expect(Size2D(width: 3, height: 4) != Size2D(width: 4, height: 4))
    }

    @Test("Hashable produces consistent hashes")
    func hashable() {
        let a = Size2D(width: 10, height: 20)
        let b = Size2D(width: 10, height: 20)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Codable round-trip preserves values")
    func codableRoundTrip() throws {
        let original = Size2D(width: 42, height: 99)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Size2D.self, from: data)
        #expect(decoded == original)
    }
}
