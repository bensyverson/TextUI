/// Extensions for matching ``KeyboardShortcut`` against ``KeyEvent`` values
/// and producing human-readable display strings.
public extension KeyboardShortcut {
    /// Returns `true` if this shortcut matches the given key event.
    ///
    /// Mapping rules:
    /// - `.control` + character → `.ctrl(lowercased character)`
    /// - `.shift` + `.tab` → `.shiftTab`
    /// - Bare character → `.character(character)`
    /// - Named keys → `.enter`, `.escape`, `.up`, etc.
    func matches(_ event: KeyEvent) -> Bool {
        // Control + character
        if modifiers.contains(.control), let char = key.character {
            return event == .ctrl(Character(char.lowercased()))
        }

        // Shift + Tab
        if modifiers.contains(.shift), key.named == .tab {
            return event == .shiftTab
        }

        // Named key (no modifiers or modifiers already handled above)
        if let named = key.named {
            switch named {
            case .return: return event == .enter
            case .escape: return event == .escape
            case .tab: return event == .tab
            case .delete: return event == .backspace
            case .upArrow: return event == .up
            case .downArrow: return event == .down
            case .leftArrow: return event == .left
            case .rightArrow: return event == .right
            }
        }

        // Bare character
        if let char = key.character, modifiers.isEmpty {
            return event == .character(char) ||
                event == .character(Character(char.uppercased())) ||
                event == .character(Character(char.lowercased()))
        }

        return false
    }

    /// A human-readable representation of this shortcut.
    ///
    /// Examples: `"^S"`, `"Tab"`, `"Enter"`, `"S-Tab"`, `"^X"`
    var displayString: String {
        var parts: [String] = []

        if modifiers.contains(.control) {
            if let char = key.character {
                return "^\(char.uppercased())"
            }
        }

        if modifiers.contains(.shift) {
            parts.append("S")
        }

        if modifiers.contains(.option) {
            parts.append("Opt")
        }

        let keyName = if let named = key.named {
            switch named {
            case .return: "Enter"
            case .escape: "Esc"
            case .tab: "Tab"
            case .delete: "Del"
            case .upArrow: "Up"
            case .downArrow: "Down"
            case .leftArrow: "Left"
            case .rightArrow: "Right"
            }
        } else if let char = key.character {
            String(char).uppercased()
        } else {
            "?"
        }

        if parts.isEmpty {
            return keyName
        }
        parts.append(keyName)
        return parts.joined(separator: "-")
    }
}
