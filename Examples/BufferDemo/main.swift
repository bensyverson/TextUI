import TextUI

/// Create a 40×10 screen
var screen = Screen(width: 40, height: 10)

/// ── Title bar ──────────────────────────
let titleStyle = Style(fg: .white, bg: .blue).bolded()
screen.back.fill(
    Region(row: 0, col: 0, width: 40, height: 1),
    style: Style(bg: .blue),
)
screen.back.write(" TextUI Buffer Demo", row: 0, col: 0, style: titleStyle)

// ── Styled ASCII text ──────────────────
screen.back.write("Bold", row: 2, col: 2, style: .bold)
screen.back.write("Dim", row: 2, col: 8, style: .dim)
screen.back.write("Italic", row: 2, col: 13, style: .italic)
screen.back.write(
    "Color!",
    row: 2,
    col: 21,
    style: Style(fg: .green).bolded(),
)

// ── Horizontal separator ───────────────
screen.back.horizontalLine(row: 4, col: 1, length: 38, style: Style(fg: .brightBlack))

/// ── CJK wide characters ───────────────
let cjkLabel = Style(fg: .cyan)
screen.back.write("CJK: ", row: 6, col: 2, style: cjkLabel)
screen.back.write("你好世界", row: 6, col: 7, style: Style(fg: .yellow).bolded())

/// ── Emoji wide characters ──────────────
let emojiLabel = Style(fg: .magenta)
screen.back.write("Emoji: ", row: 8, col: 2, style: emojiLabel)
screen.back.write("👋🎉🚀✨", row: 8, col: 9)

/// ── Flush and print ────────────────────
let output = screen.flush()
print(output)
