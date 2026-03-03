/// Shared layout algorithm for ``HStack`` and ``VStack``.
///
/// The stack layout uses a two-phase allocation:
/// 1. Subtract total spacing from available primary-axis space
/// 2. Compute each child's flexibility (max size − min size on the primary axis)
/// 3. Sort by `layoutPriority` descending, then flexibility ascending
/// 4. **Phase 1 — Minimums:** Guarantee each child its minimum size
/// 5. **Phase 2 — Surplus:** Distribute remaining space (`surplus / remainingCount`)
///    to each child in sorted order; unused portions cascade forward
/// 6. If total space < total minimums, fall back to equal-share squeeze
/// 7. Place children sequentially in original order
@MainActor
enum StackLayout {
    /// The result of laying out a single child within a stack.
    struct ChildLayout {
        /// The view to render.
        let view: any View

        /// The offset along the primary axis (col for HStack, row for VStack).
        let primaryOffset: Int

        /// The size the child chose during layout.
        let size: Size2D
    }

    /// Sendable snapshot of layout geometry, stored in ``LayoutCache``.
    struct CachedLayout: Sendable {
        /// Per-child offset and size, in original child order.
        let entries: [Entry]

        /// The total size of the stack.
        let totalSize: Size2D

        struct Entry: Sendable {
            let primaryOffset: Int
            let size: Size2D
        }
    }

    /// The axis a stack lays out along.
    enum Axis {
        case horizontal
        case vertical
    }

    /// Recursively flattens ``LayoutTransparent`` children into a flat array.
    static func flattenChildren(_ views: [any View]) -> [any View] {
        var result: [any View] = []
        for view in views {
            if let transparent = view as? LayoutTransparent {
                result.append(contentsOf: flattenChildren(transparent.layoutChildren))
            } else {
                result.append(view)
            }
        }
        return result
    }

    /// Replaces ``Spacer`` instances with axis-aware copies.
    static func prepareChildren(_ views: [any View], axis: Axis) -> [any View] {
        let spacerAxis: Spacer.Axis = axis == .horizontal ? .horizontal : .vertical
        return views.map { view in
            if let spacer = view as? Spacer {
                return spacer.withAxis(spacerAxis)
            }
            return view
        }
    }

    /// Lays out children along the given axis with the given spacing and proposal.
    ///
    /// Returns the child layouts (with offsets) and the total size of the stack.
    ///
    /// - Parameter cacheKey: When provided, the result is cached in the
    ///   per-frame ``LayoutCache`` so that identical proposals within the
    ///   same frame return instantly.
    static func layout(
        children: [any View],
        axis: Axis,
        spacing: Int,
        proposal: SizeProposal,
        context: RenderContext,
        cacheKey: String? = nil,
    ) -> (children: [ChildLayout], totalSize: Size2D) {
        guard !children.isEmpty else {
            return (children: [], totalSize: .zero)
        }

        // Check per-frame cache
        let frameCacheKey: AnyHashable? = cacheKey.map { "\($0):layout:\(proposal)" as AnyHashable }
        if let frameCacheKey,
           let cached = context.layoutCache?.get(forKey: frameCacheKey, as: CachedLayout.self),
           cached.entries.count == children.count
        {
            let layouts: [ChildLayout] = zip(children, cached.entries).map { child, entry in
                ChildLayout(view: child, primaryOffset: entry.primaryOffset, size: entry.size)
            }
            return (children: layouts, totalSize: cached.totalSize)
        }

        let totalSpacing = spacing * (children.count - 1)

        // Extract the primary and cross proposals
        let primaryProposal = axis == .horizontal ? proposal.width : proposal.height
        let crossProposal = axis == .horizontal ? proposal.height : proposal.width

        let result: (children: [ChildLayout], totalSize: Size2D)

        // Special case: nil primary proposal (ideal size query)
        if primaryProposal == nil {
            result = layoutIdeal(
                children: children,
                axis: axis,
                spacing: spacing,
                crossProposal: crossProposal,
                context: context,
            )
        } else {
            // Concrete primary proposal — run the greedy algorithm
            let available = max(0, primaryProposal! - totalSpacing)
            result = layoutGreedy(
                children: children,
                axis: axis,
                spacing: spacing,
                available: available,
                crossProposal: crossProposal,
                context: context,
            )
        }

        // Store in per-frame cache
        if let frameCacheKey {
            let cached = CachedLayout(
                entries: result.children.map {
                    CachedLayout.Entry(primaryOffset: $0.primaryOffset, size: $0.size)
                },
                totalSize: result.totalSize,
            )
            context.layoutCache?.set(cached, forKey: frameCacheKey)
        }

        return result
    }

    // MARK: - Private

    /// Ideal-size layout: query each child with nil primary proposal.
    private static func layoutIdeal(
        children: [any View],
        axis: Axis,
        spacing: Int,
        crossProposal: Int?,
        context: RenderContext,
    ) -> (children: [ChildLayout], totalSize: Size2D) {
        var layouts: [ChildLayout] = []
        var primaryOffset = 0
        var maxCross = 0

        for child in children {
            let childProposal = makeProposal(axis: axis, primary: nil, cross: crossProposal)
            let childSize = TextUI.sizeThatFits(child, proposal: childProposal, context: context)
            let primary = primaryDimension(childSize, axis: axis)
            let cross = crossDimension(childSize, axis: axis)

            layouts.append(ChildLayout(view: child, primaryOffset: primaryOffset, size: childSize))
            primaryOffset += primary + spacing
            maxCross = max(maxCross, cross)
        }

        // Remove trailing spacing
        let totalPrimary = primaryOffset - spacing
        let totalSize = makeSize(axis: axis, primary: totalPrimary, cross: maxCross)
        return (children: layouts, totalSize: totalSize)
    }

    /// Greedy layout with flexibility sorting.
    private static func layoutGreedy(
        children: [any View],
        axis: Axis,
        spacing: Int,
        available: Int,
        crossProposal: Int?,
        context: RenderContext,
    ) -> (children: [ChildLayout], totalSize: Size2D) {
        // Probe flexibility for each child
        struct FlexChild {
            let index: Int
            let view: any View
            let minSize: Int
            let maxSize: Int
            var flexibility: Int {
                maxSize - minSize
            }
        }

        let zeroProposal = makeProposal(axis: axis, primary: 0, cross: crossProposal)
        let maxProposal = makeProposal(axis: axis, primary: .max, cross: crossProposal)

        var flexChildren: [FlexChild] = children.enumerated().map { index, child in
            let minPrimary = primaryDimension(
                TextUI.sizeThatFits(child, proposal: zeroProposal, context: context),
                axis: axis,
            )
            let maxPrimary = primaryDimension(
                TextUI.sizeThatFits(child, proposal: maxProposal, context: context),
                axis: axis,
            )
            return FlexChild(index: index, view: child, minSize: minPrimary, maxSize: maxPrimary)
        }

        // Sort: priority descending first, then flexibility ascending
        flexChildren.sort { a, b in
            let aPriority = (a.view as? PrioritizedView)?.priority ?? 0
            let bPriority = (b.view as? PrioritizedView)?.priority ?? 0
            if aPriority != bPriority {
                return aPriority > bPriority
            }
            return a.flexibility < b.flexibility
        }

        // Two-phase greedy allocation:
        // Phase 1: Guarantee each child its minimum size
        // Phase 2: Distribute surplus above minimums (least flexible first)
        //
        // This prevents the equal-share division from under-allocating
        // to children with higher minimums (e.g. bordered views) when
        // multiple children have the same flexibility.
        var allocations = [Int](repeating: 0, count: children.count)
        var sizes = [Size2D](repeating: .zero, count: children.count)

        let totalMinimum = flexChildren.map(\.minSize).reduce(0, +)

        if available >= totalMinimum {
            // Enough space: start from minimums, distribute surplus
            var surplus = available - totalMinimum
            for (i, flexChild) in flexChildren.enumerated() {
                let remainingCount = flexChildren.count - i
                let share = surplus > 0 ? surplus / remainingCount : 0
                let offered = flexChild.minSize + share
                let childProposal = makeProposal(axis: axis, primary: offered, cross: crossProposal)
                let childSize = TextUI.sizeThatFits(flexChild.view, proposal: childProposal, context: context)
                let actualPrimary = primaryDimension(childSize, axis: axis)
                allocations[flexChild.index] = actualPrimary
                sizes[flexChild.index] = childSize
                surplus -= (actualPrimary - flexChild.minSize)
            }
        } else {
            // Not enough for all minimums: equal-share squeeze
            var remaining = available
            for (i, flexChild) in flexChildren.enumerated() {
                let remainingCount = flexChildren.count - i
                let share = remaining / remainingCount
                let childProposal = makeProposal(axis: axis, primary: share, cross: crossProposal)
                let childSize = TextUI.sizeThatFits(flexChild.view, proposal: childProposal, context: context)
                let actualPrimary = primaryDimension(childSize, axis: axis)
                allocations[flexChild.index] = actualPrimary
                sizes[flexChild.index] = childSize
                remaining -= actualPrimary
            }
        }

        // Place children sequentially in original order
        var layouts: [ChildLayout] = []
        var primaryOffset = 0
        var maxCross = 0

        for i in 0 ..< children.count {
            let cross = crossDimension(sizes[i], axis: axis)
            layouts.append(ChildLayout(
                view: children[i],
                primaryOffset: primaryOffset,
                size: sizes[i],
            ))
            primaryOffset += allocations[i] + spacing
            maxCross = max(maxCross, cross)
        }

        let totalPrimary = primaryOffset - spacing
        let totalSize = makeSize(axis: axis, primary: max(0, totalPrimary), cross: maxCross)
        return (children: layouts, totalSize: totalSize)
    }

    // MARK: - Axis Helpers

    private static func primaryDimension(_ size: Size2D, axis: Axis) -> Int {
        axis == .horizontal ? size.width : size.height
    }

    private static func crossDimension(_ size: Size2D, axis: Axis) -> Int {
        axis == .horizontal ? size.height : size.width
    }

    private static func makeProposal(axis: Axis, primary: Int?, cross: Int?) -> SizeProposal {
        axis == .horizontal
            ? SizeProposal(width: primary, height: cross)
            : SizeProposal(width: cross, height: primary)
    }

    private static func makeSize(axis: Axis, primary: Int, cross: Int) -> Size2D {
        axis == .horizontal
            ? Size2D(width: primary, height: cross)
            : Size2D(width: cross, height: primary)
    }
}
