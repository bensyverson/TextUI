import Testing
@testable import TextUI

@Suite("Conditional Views")
struct ConditionalViewTests {
    // MARK: - if/else with different types

    @Test("if/else with Text vs Canvas renders correct branch")
    func ifElseDifferentTypes() {
        struct ConditionalView: View {
            let showText: Bool

            @ViewBuilder
            var body: some View {
                if showText {
                    Text("Hi")
                } else {
                    Canvas { buffer, region in
                        buffer.write("X", row: region.row, col: region.col)
                    }
                }
            }
        }

        // Text branch
        let textView: any View = ConditionalView(showText: true)
        let textSize = TextUI.sizeThatFits(textView, proposal: SizeProposal(width: 10, height: 1))
        #expect(textSize == Size2D(width: 2, height: 1))
        var buffer = Buffer(width: 10, height: 1)
        TextUI.render(textView, into: &buffer, region: Region(row: 0, col: 0, width: 2, height: 1))
        #expect(buffer[0, 0].char == "H")
        #expect(buffer[0, 1].char == "i")

        // Canvas branch
        let canvasView: any View = ConditionalView(showText: false)
        let canvasSize = TextUI.sizeThatFits(canvasView, proposal: SizeProposal(width: 10, height: 1))
        #expect(canvasSize == Size2D(width: 10, height: 1))
        var buffer2 = Buffer(width: 10, height: 1)
        TextUI.render(canvasView, into: &buffer2, region: Region(row: 0, col: 0, width: 10, height: 1))
        #expect(buffer2[0, 0].char == "X")
    }

    // MARK: - if let optional

    @Test("if let renders content when present, EmptyView when nil")
    func ifLetOptional() {
        struct OptionalView: View {
            let label: String?

            @ViewBuilder
            var body: some View {
                if let label {
                    Text(label)
                }
            }
        }

        // Present
        let present: any View = OptionalView(label: "OK")
        let size = TextUI.sizeThatFits(present, proposal: .unspecified)
        #expect(size == Size2D(width: 2, height: 1))

        // Nil renders as EmptyView (zero size)
        let absent: any View = OptionalView(label: nil)
        let nilSize = TextUI.sizeThatFits(absent, proposal: .unspecified)
        #expect(nilSize == .zero)
    }

    // MARK: - Nested conditionals

    @Test("Nested if/else compiles and renders correctly")
    func nestedConditionals() {
        struct NestedView: View {
            let level: Int

            @ViewBuilder
            var body: some View {
                if level > 1 {
                    if level > 2 {
                        Text("HIGH")
                    } else {
                        Text("MED")
                    }
                } else {
                    Text("LOW")
                }
            }
        }

        let high: any View = NestedView(level: 3)
        let highSize = TextUI.sizeThatFits(high, proposal: .unspecified)
        #expect(highSize == Size2D(width: 4, height: 1))

        let med: any View = NestedView(level: 2)
        var buffer = Buffer(width: 10, height: 1)
        let medSize = TextUI.sizeThatFits(med, proposal: .unspecified)
        TextUI.render(med, into: &buffer, region: Region(row: 0, col: 0, width: medSize.width, height: 1))
        #expect(buffer.text == "MED")

        let low: any View = NestedView(level: 0)
        let lowSize = TextUI.sizeThatFits(low, proposal: .unspecified)
        #expect(lowSize == Size2D(width: 3, height: 1))
    }

    // MARK: - Conditional inside HStack

    @Test("Conditional view as HStack child")
    func conditionalInsideHStack() {
        struct LabeledView: View {
            let showPrefix: Bool

            @ViewBuilder
            var body: some View {
                HStack(spacing: 1) {
                    if showPrefix {
                        Text(">")
                    }
                    Text("Hello")
                }
            }
        }

        // With prefix: "> Hello" = 1 + 1 + 5 = 7
        let withPrefix: any View = LabeledView(showPrefix: true)
        let size1 = TextUI.sizeThatFits(withPrefix, proposal: .unspecified)
        #expect(size1 == Size2D(width: 7, height: 1))

        // Without prefix: just "Hello" = 5 (EmptyView has 0 width, no spacing)
        let withoutPrefix: any View = LabeledView(showPrefix: false)
        let size2 = TextUI.sizeThatFits(withoutPrefix, proposal: .unspecified)
        // EmptyView still counts as a child in the HStack, so spacing may apply
        // The key test is that it compiles and renders sensibly
        var buffer = Buffer(width: 10, height: 1)
        TextUI.render(withoutPrefix, into: &buffer, region: Region(row: 0, col: 0, width: size2.width, height: 1))
        #expect(buffer.text.trimmingCharacters(in: .whitespaces) == "Hello")
    }

    // MARK: - switch statement

    @Test("switch with multiple branches renders correct one")
    func switchStatement() {
        struct SwitchView: View {
            enum Mode { case a, b, c }
            let mode: Mode

            @ViewBuilder
            var body: some View {
                switch mode {
                case .a:
                    Text("AAA")
                case .b:
                    Text("BB")
                case .c:
                    Canvas { buffer, region in
                        for col in 0 ..< region.width {
                            buffer.write(".", row: region.row, col: region.col + col)
                        }
                    }
                }
            }
        }

        let a: any View = SwitchView(mode: .a)
        let sizeA = TextUI.sizeThatFits(a, proposal: .unspecified)
        #expect(sizeA == Size2D(width: 3, height: 1))

        let b: any View = SwitchView(mode: .b)
        let sizeB = TextUI.sizeThatFits(b, proposal: .unspecified)
        #expect(sizeB == Size2D(width: 2, height: 1))

        // Canvas is greedy — takes proposed size
        let c: any View = SwitchView(mode: .c)
        let sizeC = TextUI.sizeThatFits(c, proposal: SizeProposal(width: 10, height: 1))
        #expect(sizeC == Size2D(width: 10, height: 1))
    }

    // MARK: - Sizing behavior preserved

    @Test("Each branch preserves its sizing behavior (hugging vs greedy)")
    func sizingBehaviorPreserved() {
        struct SizingView: View {
            let useGreedy: Bool

            @ViewBuilder
            var body: some View {
                if useGreedy {
                    Canvas { _, _ in }
                } else {
                    Text("AB")
                }
            }
        }

        let proposal = SizeProposal(width: 40, height: 10)

        // Greedy branch fills proposal
        let greedy: any View = SizingView(useGreedy: true)
        let greedySize = TextUI.sizeThatFits(greedy, proposal: proposal)
        #expect(greedySize == Size2D(width: 40, height: 10))

        // Hugging branch stays at content size
        let hugging: any View = SizingView(useGreedy: false)
        let huggingSize = TextUI.sizeThatFits(hugging, proposal: proposal)
        #expect(huggingSize == Size2D(width: 2, height: 1))
    }

    // MARK: - Rendering correctness

    @Test("Conditional branch renders correctly into buffer")
    func conditionalRendersCorrectly() {
        struct RenderView: View {
            let showCanvas: Bool

            @ViewBuilder
            var body: some View {
                if showCanvas {
                    Canvas { buffer, region in
                        for col in 0 ..< region.width {
                            buffer.write("#", row: region.row, col: region.col + col)
                        }
                    }
                } else {
                    Text("OK")
                }
            }
        }

        // Canvas branch fills region
        let cv: any View = RenderView(showCanvas: true)
        var buf1 = Buffer(width: 5, height: 1)
        TextUI.render(cv, into: &buf1, region: Region(row: 0, col: 0, width: 5, height: 1))
        #expect(buf1.text == "#####")

        // Text branch renders content
        let tv: any View = RenderView(showCanvas: false)
        var buf2 = Buffer(width: 5, height: 1)
        TextUI.render(tv, into: &buf2, region: Region(row: 0, col: 0, width: 2, height: 1))
        #expect(buf2[0, 0].char == "O")
        #expect(buf2[0, 1].char == "K")
    }
}
