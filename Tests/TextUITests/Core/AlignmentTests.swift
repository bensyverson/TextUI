import Foundation
import Testing
@testable import TextUI

@MainActor
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

    // MARK: - Combined Alignment

    @Test("All 9 static constants exist")
    func combinedStaticConstants() {
        let all: [Alignment] = [
            .topLeading, .top, .topTrailing,
            .leading, .center, .trailing,
            .bottomLeading, .bottom, .bottomTrailing,
        ]
        #expect(all.count == 9)
    }

    @Test("Center alignment produces correct components")
    func centerComponents() {
        #expect(Alignment.center.horizontal == .center)
        #expect(Alignment.center.vertical == .center)
    }

    @Test("TopLeading alignment produces correct components")
    func topLeadingComponents() {
        #expect(Alignment.topLeading.horizontal == .leading)
        #expect(Alignment.topLeading.vertical == .top)
    }

    @Test("BottomTrailing alignment produces correct components")
    func bottomTrailingComponents() {
        #expect(Alignment.bottomTrailing.horizontal == .trailing)
        #expect(Alignment.bottomTrailing.vertical == .bottom)
    }

    @Test("Offset centers child in container")
    func offsetCenter() {
        let child = Size2D(width: 4, height: 2)
        let container = Size2D(width: 10, height: 6)
        let offset = Alignment.center.offset(child: child, in: container)
        #expect(offset.col == 3) // (10 - 4) / 2
        #expect(offset.row == 2) // (6 - 2) / 2
    }

    @Test("Offset topLeading is zero")
    func offsetTopLeading() {
        let child = Size2D(width: 4, height: 2)
        let container = Size2D(width: 10, height: 6)
        let offset = Alignment.topLeading.offset(child: child, in: container)
        #expect(offset.col == 0)
        #expect(offset.row == 0)
    }

    @Test("Offset bottomTrailing pushes to edge")
    func offsetBottomTrailing() {
        let child = Size2D(width: 4, height: 2)
        let container = Size2D(width: 10, height: 6)
        let offset = Alignment.bottomTrailing.offset(child: child, in: container)
        #expect(offset.col == 6) // 10 - 4
        #expect(offset.row == 4) // 6 - 2
    }

    @Test("Offset clamps to zero when child larger than container")
    func offsetClampedToZero() {
        let child = Size2D(width: 20, height: 10)
        let container = Size2D(width: 5, height: 3)
        let offset = Alignment.bottomTrailing.offset(child: child, in: container)
        #expect(offset.col == 0)
        #expect(offset.row == 0)
    }

    @Test("Offset same size is zero for all alignments")
    func offsetSameSize() {
        let size = Size2D(width: 5, height: 3)
        for alignment in [Alignment.topLeading, .center, .bottomTrailing] {
            let offset = alignment.offset(child: size, in: size)
            #expect(offset.col == 0)
            #expect(offset.row == 0)
        }
    }

    @Test("Alignment Codable round-trip")
    func combinedCodable() throws {
        let alignment = Alignment.center
        let data = try JSONEncoder().encode(alignment)
        let decoded = try JSONDecoder().decode(Alignment.self, from: data)
        #expect(decoded == alignment)
    }

    @Test("Alignment Equatable")
    func combinedEquatable() {
        #expect(Alignment.center == Alignment(horizontal: .center, vertical: .center))
        #expect(Alignment.topLeading != Alignment.bottomTrailing)
    }
}
