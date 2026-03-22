import Testing
@testable import TextUI

@MainActor
@Suite("Region")
struct RegionTests {
    @Test("Basic region properties")
    func basicProperties() {
        let region = Region(row: 1, col: 2, width: 10, height: 5)
        #expect(region.row == 1)
        #expect(region.col == 2)
        #expect(region.width == 10)
        #expect(region.height == 5)
    }

    @Test("isEmpty for zero dimensions")
    func isEmptyZero() {
        #expect(Region(row: 0, col: 0, width: 0, height: 5).isEmpty)
        #expect(Region(row: 0, col: 0, width: 5, height: 0).isEmpty)
        #expect(Region(row: 0, col: 0, width: 0, height: 0).isEmpty)
    }

    @Test("isEmpty for negative dimensions")
    func isEmptyNegative() {
        #expect(Region(row: 0, col: 0, width: -1, height: 5).isEmpty)
        #expect(Region(row: 0, col: 0, width: 5, height: -1).isEmpty)
    }

    @Test("isEmpty false for positive dimensions")
    func isNotEmpty() {
        #expect(!Region(row: 0, col: 0, width: 1, height: 1).isEmpty)
    }

    @Test("Subregion offsets from parent origin")
    func subregionOffset() {
        let parent = Region(row: 10, col: 20, width: 40, height: 30)
        let child = parent.subregion(row: 5, col: 5, width: 10, height: 10)
        #expect(child.row == 15)
        #expect(child.col == 25)
        #expect(child.width == 10)
        #expect(child.height == 10)
    }

    @Test("Subregion clamps to parent bounds")
    func subregionClamping() {
        let parent = Region(row: 0, col: 0, width: 10, height: 10)
        let child = parent.subregion(row: 5, col: 5, width: 20, height: 20)
        #expect(child.width == 5)
        #expect(child.height == 5)
    }

    @Test("Inset reduces size")
    func insetBasic() {
        let region = Region(row: 0, col: 0, width: 20, height: 10)
        let inset = region.inset(top: 1, left: 2, bottom: 1, right: 2)
        #expect(inset.row == 1)
        #expect(inset.col == 2)
        #expect(inset.width == 16)
        #expect(inset.height == 8)
    }

    @Test("Inset clamps width and height to zero")
    func insetClamping() {
        let region = Region(row: 0, col: 0, width: 5, height: 5)
        let inset = region.inset(top: 0, left: 10, bottom: 0, right: 10)
        #expect(inset.width == 0)
        #expect(inset.height == 5)
    }

    @Test("Equality")
    func equality() {
        let a = Region(row: 1, col: 2, width: 3, height: 4)
        let b = Region(row: 1, col: 2, width: 3, height: 4)
        let c = Region(row: 0, col: 2, width: 3, height: 4)
        #expect(a == b)
        #expect(a != c)
    }

    // MARK: - Hit Testing

    @Test("contains: point inside region")
    func containsInside() {
        let region = Region(row: 5, col: 10, width: 20, height: 10)
        #expect(region.contains(row: 10, column: 20))
    }

    @Test("contains: point at top-left origin")
    func containsOrigin() {
        let region = Region(row: 5, col: 10, width: 20, height: 10)
        #expect(region.contains(row: 5, column: 10))
    }

    @Test("contains: point at bottom-right boundary is exclusive")
    func containsBoundaryExclusive() {
        let region = Region(row: 5, col: 10, width: 20, height: 10)
        #expect(!region.contains(row: 15, column: 30)) // row 5+10, col 10+20
    }

    @Test("contains: point above region")
    func containsAbove() {
        let region = Region(row: 5, col: 10, width: 20, height: 10)
        #expect(!region.contains(row: 4, column: 15))
    }

    @Test("contains: point below region")
    func containsBelow() {
        let region = Region(row: 5, col: 10, width: 20, height: 10)
        #expect(!region.contains(row: 15, column: 15))
    }

    @Test("contains: point left of region")
    func containsLeft() {
        let region = Region(row: 5, col: 10, width: 20, height: 10)
        #expect(!region.contains(row: 7, column: 9))
    }

    @Test("contains: point right of region")
    func containsRight() {
        let region = Region(row: 5, col: 10, width: 20, height: 10)
        #expect(!region.contains(row: 7, column: 30))
    }

    @Test("contains: empty region contains nothing")
    func containsEmpty() {
        let region = Region(row: 0, col: 0, width: 0, height: 0)
        #expect(!region.contains(row: 0, column: 0))
    }
}
