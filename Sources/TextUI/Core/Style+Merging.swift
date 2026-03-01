public extension Style {
    /// Returns a new style where boolean attributes are OR'd together
    /// and non-nil colors from `override` replace this style's values.
    ///
    /// This is used by `StyledView` for additive style application:
    /// `.bold()` adds bold without clearing foreground color,
    /// `.foregroundColor(.red)` sets foreground without touching background.
    func merging(_ override: Style) -> Style {
        Style(
            fg: override.fg ?? fg,
            bg: override.bg ?? bg,
            bold: bold || override.bold,
            dim: dim || override.dim,
            italic: italic || override.italic,
            underline: underline || override.underline,
            inverse: inverse || override.inverse,
            strikethrough: strikethrough || override.strikethrough,
        )
    }
}
