# Terminal I/O

Terminal control, keyboard input, and color capability detection.

## Overview

TextUI's terminal layer provides low-level control over the terminal emulator. It handles:

- **Raw mode**: Disabling line buffering and echo so each keypress is received immediately
- **Alternate screen**: Saving and restoring the user's terminal content
- **Keyboard input**: Parsing raw ANSI escape sequences into structured ``KeyEvent`` values
- **Color detection**: Auto-detecting terminal color capability and downgrading colors to match

### Terminal Control

``Terminal`` provides static methods for entering and exiting raw mode, managing the alternate screen buffer, cursor visibility, and querying terminal size. Signal handlers can be installed for resize (SIGWINCH) and shutdown (SIGTERM) events.

### Keyboard Input

``KeyReader`` spawns a dedicated OS thread to read from stdin (since `read()` is a blocking call that can't be cancelled by Swift concurrency). It produces an `AsyncStream<KeyEvent>` that the run loop consumes.

``KeyEvent`` represents all supported key inputs — printable characters (including multi-byte UTF-8), arrow keys, function keys (F1–F12), navigation keys (Home, End, Page Up/Down), modifier combinations (Ctrl+key, Shift+Tab), and escape.

### Color Capability

``ColorCapability`` detects what the terminal supports by inspecting environment variables (`NO_COLOR`, `COLORTERM`, `TERM`). When the capability is lower than trueColor, the ``Screen`` automatically downgrades RGB colors to palette-256 or basic-16 during ``Screen/flush()``.

## Topics

### Terminal Control

- ``Terminal``
- ``Terminal/Size-swift.struct``

### Keyboard Input

- ``KeyEvent``
- ``KeyReader``

### Color

- ``ColorCapability``
