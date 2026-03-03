import Foundation
import Testing
@testable import TextUI

@MainActor
@Suite("SizeProposal")
struct SizeProposalTests {
    // MARK: - Static Constants

    @Test("Unspecified is (nil, nil)")
    func unspecified() {
        #expect(SizeProposal.unspecified.width == nil)
        #expect(SizeProposal.unspecified.height == nil)
    }

    @Test("Zero is (0, 0)")
    func zero() {
        #expect(SizeProposal.zero.width == 0)
        #expect(SizeProposal.zero.height == 0)
    }

    @Test("Max is (.max, .max)")
    func max() {
        #expect(SizeProposal.max.width == .max)
        #expect(SizeProposal.max.height == .max)
    }

    // MARK: - Inset

    @Test("Inset subtracts from concrete dimensions")
    func insetConcrete() {
        let proposal = SizeProposal(width: 80, height: 24)
        let inset = proposal.inset(horizontal: 10, vertical: 4)
        #expect(inset.width == 70)
        #expect(inset.height == 20)
    }

    @Test("Inset preserves nil dimensions")
    func insetNil() {
        let proposal = SizeProposal(width: nil, height: 24)
        let inset = proposal.inset(horizontal: 10, vertical: 4)
        #expect(inset.width == nil)
        #expect(inset.height == 20)
    }

    @Test("Inset clamps to zero")
    func insetClampsToZero() {
        let proposal = SizeProposal(width: 5, height: 3)
        let inset = proposal.inset(horizontal: 10, vertical: 10)
        #expect(inset.width == 0)
        #expect(inset.height == 0)
    }

    // MARK: - Replacing Unspecified

    @Test("ReplacingUnspecified fills nil dimensions")
    func replacingUnspecifiedFillsNil() {
        let proposal = SizeProposal(width: nil, height: nil)
        let replaced = proposal.replacingUnspecified(width: 80, height: 24)
        #expect(replaced.width == 80)
        #expect(replaced.height == 24)
    }

    @Test("ReplacingUnspecified preserves concrete dimensions")
    func replacingUnspecifiedPreservesConcrete() {
        let proposal = SizeProposal(width: 40, height: 12)
        let replaced = proposal.replacingUnspecified(width: 80, height: 24)
        #expect(replaced.width == 40)
        #expect(replaced.height == 12)
    }

    // MARK: - Codable

    @Test("Codable round-trip with nil dimensions")
    func codableWithNil() throws {
        let original = SizeProposal(width: nil, height: 10)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SizeProposal.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trip with concrete dimensions")
    func codableConcrete() throws {
        let original = SizeProposal(width: 80, height: 24)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SizeProposal.self, from: data)
        #expect(decoded == original)
    }
}
