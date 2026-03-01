# Layout System

How TextUI measures and positions views using size proposals and a greedy stack algorithm.

## Overview

TextUI's layout engine follows the same proposal/response contract as SwiftUI:
a parent **proposes** a size to its child, the child **responds** with the size
it actually needs, and the parent positions the child within its allocated region.
The child always chooses its own size — the proposal is advisory.

### The Proposal/Response Contract

Layout happens in two passes:

1. **Sizing pass:** The parent calls ``sizeThatFits(_:proposal:context:)`` on the child
   with a ``SizeProposal``. The child returns a ``Size2D``.
2. **Render pass:** The parent calls ``render(_:into:region:context:)`` with a ``Region``
   matching the child's chosen size. The child renders itself into the buffer.

### Four Proposal Modes

Each dimension of a ``SizeProposal`` can carry one of four values:

| Value | Meaning | Example |
|-------|---------|---------|
| `nil` | **Ideal** — how big do you *want* to be? | Stack computing its own ideal size |
| `0` | **Minimum** — how small *can* you be? | Probing flexibility |
| `.max` | **Maximum** — how big *can* you be? | Probing flexibility |
| Concrete | **Offer** — I have this many cells for you | Normal layout |

### Three View Categories

Views fall into three sizing categories based on how they respond to proposals:

- **Hugging** (e.g. ``Text``): Prefers its natural content size. Never expands
  beyond it, but can shrink (with truncation) when proposed less.
- **Expanding** (e.g. ``Spacer``, ``Divider``): Grows to fill the proposed size
  along its primary axis.
- **Neutral** (e.g. stacks): Size depends entirely on children.

## Stack Layout Algorithm

``HStack`` and ``VStack`` use a shared flexibility-sorted greedy algorithm
implemented in `StackLayout`:

1. **Spacing:** Subtract `spacing × (childCount - 1)` from available primary-axis space.
2. **Flexibility probing:** For each child, query `sizeThatFits(0)` and
   `sizeThatFits(.max)` on the primary axis. Flexibility = max - min.
3. **Sort by flexibility ascending:** Least flexible children are allocated first.
4. **Greedy allocation:** Each child receives `remaining / remainingCount` cells.
   It responds with its actual size; unneeded surplus cascades to the next child.
5. **Placement:** Children are positioned sequentially along the primary axis.

The stack's total primary size is the sum of children plus spacing. Its cross
size is the maximum of all children's cross sizes.

### Ideal Size Edge Case

When the stack receives a `nil` primary proposal (ideal size query), the greedy
algorithm is bypassed. Each child is queried with `nil` individually, and the
results are summed with spacing.

## Topics

### Size Negotiation

- ``Size2D``
- ``SizeProposal``
- ``sizeThatFits(_:proposal:context:)``
- ``render(_:into:region:context:)``

### Alignment

- ``HorizontalAlignment``
- ``VerticalAlignment``

### Stacks

- ``HStack``
- ``VStack``
