/// `Never` conforms to `View` so it can serve as the `Body` type
/// for primitive views. Its `body` is never called.
extension Never: View {
    public typealias Body = Never

    public var body: Never {
        fatalError("Never has no body")
    }
}
