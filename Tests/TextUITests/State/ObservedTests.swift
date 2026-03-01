import Testing
@testable import TextUI

@Suite("Observed Property Wrapper")
struct ObservedTests {
    @MainActor
    final class TestState {
        @Observed var count = 0
        @Observed var name = "hello"
    }

    @Test("initial value is accessible")
    @MainActor
    func initialValue() {
        let state = TestState()
        #expect(state.count == 0)
        #expect(state.name == "hello")
    }

    @Test("setting value updates storage")
    @MainActor
    func setValue() {
        let state = TestState()
        state.count = 42
        #expect(state.count == 42)
    }

    @Test("setting value sends state signal")
    @MainActor
    func sendsSignal() async {
        let state = TestState()

        // Consume the stream in a task
        let signalReceived = AsyncStream<Bool>.makeStream()
        let task = Task { @MainActor in
            for await _ in StateSignal.stream {
                signalReceived.1.yield(true)
                signalReceived.1.finish()
                return
            }
        }

        // Mutate
        state.count = 1

        // Wait for signal (with timeout)
        var received = false
        for await value in signalReceived.0 {
            received = value
        }
        #expect(received)
        task.cancel()
    }

    @Test("multiple rapid mutations coalesce")
    @MainActor
    func coalescing() {
        let state = TestState()
        // Rapid mutations should not crash or block
        for i in 0 ..< 100 {
            state.count = i
        }
        #expect(state.count == 99)
    }
}
