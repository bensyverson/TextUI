import Testing
@testable import TextUI

@MainActor
@Suite("ProgressView")
struct ProgressViewTests {
    // MARK: - Compact Indeterminate

    @Test("Compact indeterminate sizes to 1x1")
    func compactIndeterminateSizing() {
        let pv = ProgressView()
        var ctx = RenderContext()
        ctx.progressViewStyle = .compact
        let size = RenderEnvironment.$current.withValue(ctx) {
            sizeThatFits(pv, proposal: SizeProposal(width: 40, height: 10), context: ctx)
        }
        #expect(size == Size2D(width: 1, height: 1))
    }

    @Test("Compact indeterminate renders spinner char")
    func compactIndeterminateRenders() {
        let tracker = AnimationTracker()
        var ctx = RenderContext()
        ctx.animationTracker = tracker
        ctx.progressViewStyle = .compact
        let pv = ProgressView()

        var buffer = Buffer(width: 5, height: 1)
        let region = Region(row: 0, col: 0, width: 5, height: 1)

        RenderEnvironment.$current.withValue(ctx) {
            let size = sizeThatFits(pv, proposal: SizeProposal(width: 5, height: 1), context: ctx)
            let renderRegion = Region(row: 0, col: 0, width: size.width, height: size.height)
            render(pv, into: &buffer, region: renderRegion, context: ctx)
        }

        // First frame (tick 0) should render the first spinner frame "⠋"
        #expect(buffer[0, 0].char == "⠋")
    }

    @Test("Compact indeterminate varies with tick")
    func compactIndeterminateVaries() {
        let tracker = AnimationTracker()
        tracker.tick() // tick = 1
        var ctx = RenderContext()
        ctx.animationTracker = tracker
        ctx.progressViewStyle = .compact
        let pv = ProgressView()

        var buffer = Buffer(width: 5, height: 1)

        RenderEnvironment.$current.withValue(ctx) {
            let size = sizeThatFits(pv, proposal: SizeProposal(width: 5, height: 1), context: ctx)
            let renderRegion = Region(row: 0, col: 0, width: size.width, height: size.height)
            render(pv, into: &buffer, region: renderRegion, context: ctx)
        }

        // tick 1 should render the second spinner frame "⠙"
        #expect(buffer[0, 0].char == "⠙")
    }

    // MARK: - Compact Determinate

    @Test("Compact determinate at 0.0")
    func compactDeterminateZero() {
        var ctx = RenderContext()
        ctx.progressViewStyle = .compact
        let pv = ProgressView(value: 0.0)

        var buffer = Buffer(width: 5, height: 1)
        RenderEnvironment.$current.withValue(ctx) {
            let size = sizeThatFits(pv, proposal: SizeProposal(width: 5, height: 1), context: ctx)
            let region = Region(row: 0, col: 0, width: size.width, height: size.height)
            render(pv, into: &buffer, region: region, context: ctx)
        }
        // 0% progress → first block char "▏"
        #expect(buffer[0, 0].char == "▏")
    }

    @Test("Compact determinate at 1.0")
    func compactDeterminateFull() {
        var ctx = RenderContext()
        ctx.progressViewStyle = .compact
        let pv = ProgressView(value: 1.0)

        var buffer = Buffer(width: 5, height: 1)
        RenderEnvironment.$current.withValue(ctx) {
            let size = sizeThatFits(pv, proposal: SizeProposal(width: 5, height: 1), context: ctx)
            let region = Region(row: 0, col: 0, width: size.width, height: size.height)
            render(pv, into: &buffer, region: region, context: ctx)
        }
        // 100% progress → full block "█"
        #expect(buffer[0, 0].char == "█")
    }

    @Test("Compact determinate at 0.5")
    func compactDeterminateHalf() {
        var ctx = RenderContext()
        ctx.progressViewStyle = .compact
        let pv = ProgressView(value: 0.5)

        var buffer = Buffer(width: 5, height: 1)
        RenderEnvironment.$current.withValue(ctx) {
            let size = sizeThatFits(pv, proposal: SizeProposal(width: 5, height: 1), context: ctx)
            let region = Region(row: 0, col: 0, width: size.width, height: size.height)
            render(pv, into: &buffer, region: region, context: ctx)
        }
        // 50% → middle block char (index 3 of 8: "▌")
        #expect(buffer[0, 0].char == "▌")
    }

    // MARK: - Bar Determinate

    @Test("Bar determinate sizing: greedy width, height 1")
    func barDeterminateSizing() {
        let pv = ProgressView(value: 0.5)
        var ctx = RenderContext()
        ctx.progressViewStyle = .bar(showPercent: true)
        let size = RenderEnvironment.$current.withValue(ctx) {
            sizeThatFits(pv, proposal: SizeProposal(width: 40, height: 10), context: ctx)
        }
        #expect(size.width == 40)
        #expect(size.height == 1)
    }

    @Test("Bar determinate renders filled and empty portions")
    func barDeterminateRenders() {
        let pv = ProgressView(value: 0.5)
        var ctx = RenderContext()
        ctx.progressViewStyle = .bar(showPercent: false)
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        RenderEnvironment.$current.withValue(ctx) {
            render(pv, into: &buffer, region: region, context: ctx)
        }

        // 50% of 10 = 5 filled, 5 empty
        #expect(buffer[0, 0].char == "▓")
        #expect(buffer[0, 4].char == "▓")
        #expect(buffer[0, 5].char == "░")
        #expect(buffer[0, 9].char == "░")
    }

    @Test("Bar determinate with percent text")
    func barDeterminateWithPercent() {
        let pv = ProgressView(value: 0.42)
        var ctx = RenderContext()
        ctx.progressViewStyle = .bar(showPercent: true)
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        RenderEnvironment.$current.withValue(ctx) {
            render(pv, into: &buffer, region: region, context: ctx)
        }

        // Bar width = 20 - 5 = 15; percent region starts at col 15
        // Read percentage text from the right side
        let percentText = (16 ..< 20).map { String(buffer[0, $0].char) }.joined()
        #expect(percentText == " 42%")
    }

    // MARK: - Bar Indeterminate

    @Test("Bar indeterminate renders animated pattern")
    func barIndeterminateRenders() {
        let tracker = AnimationTracker()
        var ctx = RenderContext()
        ctx.animationTracker = tracker
        ctx.progressViewStyle = .bar(showPercent: false)
        let pv = ProgressView()

        var buffer = Buffer(width: 8, height: 1)
        let region = Region(row: 0, col: 0, width: 8, height: 1)

        RenderEnvironment.$current.withValue(ctx) {
            render(pv, into: &buffer, region: region, context: ctx)
        }

        // tick=0: pattern at col 0 = (0+0)%4=0 → ▓, col 1 = (1+0)%4=1 → ░, etc.
        #expect(buffer[0, 0].char == "▓")
        #expect(buffer[0, 1].char == "░")
        #expect(buffer[0, 4].char == "▓")
    }

    // MARK: - With Label

    @Test("With label renders label and progress")
    func withLabel() {
        var ctx = RenderContext()
        ctx.progressViewStyle = .compact
        let pv = ProgressView("Loading")

        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        RenderEnvironment.$current.withValue(ctx) {
            render(pv, into: &buffer, region: region, context: ctx)
        }

        // Label "Loading" should appear at start
        let text = (0 ..< 7).map { String(buffer[0, $0].char) }.joined()
        #expect(text == "Loading")
    }

    // MARK: - Default Style

    @Test("Default style: compact for indeterminate")
    func defaultIndeterminate() {
        let pv = ProgressView()
        let tracker = AnimationTracker()
        var ctx = RenderContext()
        ctx.animationTracker = tracker
        // No explicit style set

        let size = RenderEnvironment.$current.withValue(ctx) {
            sizeThatFits(pv, proposal: SizeProposal(width: 40, height: 10), context: ctx)
        }
        // Compact indeterminate → 1x1
        #expect(size == Size2D(width: 1, height: 1))
    }

    @Test("Default style: bar for determinate")
    func defaultDeterminate() {
        let pv = ProgressView(value: 0.5)
        var ctx = RenderContext()
        // No explicit style set

        let size = RenderEnvironment.$current.withValue(ctx) {
            sizeThatFits(pv, proposal: SizeProposal(width: 40, height: 10), context: ctx)
        }
        // Bar determinate → greedy width
        #expect(size.width == 40)
        #expect(size.height == 1)
    }

    // MARK: - Style Override

    @Test(".progressViewStyle(.compact) overrides determinate default")
    func compactOverrideDeterminate() {
        var ctx = RenderContext()
        ctx.progressViewStyle = .compact
        let pv = ProgressView(value: 0.5)

        let size = RenderEnvironment.$current.withValue(ctx) {
            sizeThatFits(pv, proposal: SizeProposal(width: 40, height: 10), context: ctx)
        }
        // Compact → 1x1
        #expect(size == Size2D(width: 1, height: 1))
    }

    @Test(".progressViewStyle(.bar()) overrides indeterminate default")
    func barOverrideIndeterminate() {
        var ctx = RenderContext()
        ctx.progressViewStyle = .bar(showPercent: false)
        let pv = ProgressView()

        let size = RenderEnvironment.$current.withValue(ctx) {
            sizeThatFits(pv, proposal: SizeProposal(width: 40, height: 10), context: ctx)
        }
        // Bar → greedy width
        #expect(size.width == 40)
    }
}
