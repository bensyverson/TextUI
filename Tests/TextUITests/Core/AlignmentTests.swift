import Foundation
import Testing
@testable import TextUI

@Suite("Alignment")
struct AlignmentTests {
    // MARK: - HorizontalAlignment

    @Test("HorizontalAlignment has all expected cases")
    func horizontalCases() {
        let cases: [HorizontalAlignment] = [.leading, .center, .trailing]
        #expect(cases.count == 3)
    }

    @Test("HorizontalAlignment Codable round-trip")
    func horizontalCodable() throws {
        for alignment in [HorizontalAlignment.leading, .center, .trailing] {
            let data = try JSONEncoder().encode(alignment)
            let decoded = try JSONDecoder().decode(HorizontalAlignment.self, from: data)
            #expect(decoded == alignment)
        }
    }

    // MARK: - VerticalAlignment

    @Test("VerticalAlignment has all expected cases")
    func verticalCases() {
        let cases: [VerticalAlignment] = [.top, .center, .bottom]
        #expect(cases.count == 3)
    }

    @Test("VerticalAlignment Codable round-trip")
    func verticalCodable() throws {
        for alignment in [VerticalAlignment.top, .center, .bottom] {
            let data = try JSONEncoder().encode(alignment)
            let decoded = try JSONDecoder().decode(VerticalAlignment.self, from: data)
            #expect(decoded == alignment)
        }
    }
}
