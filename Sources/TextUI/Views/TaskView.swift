/// A primitive view that runs an async task while its content is in the view tree.
///
/// When `TaskView` is rendered, it marks its key as active in the
/// ``TaskStore``. On the first frame, the store spawns the task. When
/// the view is removed from the tree (its key is no longer marked
/// active), the store cancels the task automatically.
///
/// This view is not used directly — apply it via the `.task {}` modifier
/// on ``View``.
struct TaskView: PrimitiveView {
    let content: any View
    let action: @MainActor @Sendable () async -> Void
    let key: String

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        TextUI.sizeThatFits(content, proposal: proposal, context: context)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        context.taskStore?.markActive(key: key, action: action)
        TextUI.render(content, into: &buffer, region: region, context: context)
    }
}
