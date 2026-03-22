# Terminal I/O

Terminal control, keyboard input, and color capability detection.

## Overview

TextUI's terminal layer provides low-level control over the terminal emulator. It handles:

- **Raw mode**: Disabling line buffering and echo so each keypress is received immediately
- **Alternate screen**: Saving and restoring the user's terminal content
- **Keyboard input**: Parsing raw ANSI escape sequences into structured ``KeyEvent`` values
- **Color detection**: Auto-detecting terminal color capability and downgrading colors to match

### Terminal Control

``Terminal`` provides static methods for entering and exiting raw mode, managing the alternate screen buffer, cursor visibility, and querying terminal size. Signal handlers can be installed for resize (SIGWINCH) and shutdown (SIGTERM) events. Resize events use a self-pipe pattern internally for async-signal safety, exposed via ``Terminal/resizeEvents()``.

### Keyboard Input

``KeyReader`` spawns a dedicated OS thread to read from stdin (since `read()` is a blocking call that can't be cancelled by Swift concurrency). It produces an `AsyncStream` of ``InputEvent`` values that the run loop consumes.

``InputEvent`` is the unified input type, wrapping both ``KeyEvent`` (keyboard) and ``MouseEvent`` (mouse) into a single stream. The parser automatically distinguishes SGR mouse escape sequences from keyboard input.

``KeyEvent`` represents all supported key inputs — printable characters (including multi-byte UTF-8), arrow keys, function keys (F1–F12), navigation keys (Home, End, Page Up/Down), modifier combinations (Ctrl+key, Shift+Tab, Shift+Arrow, Ctrl+Arrow, Ctrl+Shift+Arrow), and escape.

### Mouse Tracking

When mouse events are enabled (the default), TextUI activates SGR extended mouse mode in the terminal. This captures left-click, right-click, and scroll wheel events as ``MouseEvent`` values with screen coordinates and modifier keys.

Mouse tracking can be disabled per-application by overriding ``App/allowsMouseEvents``. When disabled, the terminal behaves normally — text selection and copy/paste work as expected.

> Note: When mouse tracking is active, the terminal captures mouse input, which disables native text selection. Users can still select text using terminal-specific workarounds (e.g. hold Option in iTerm2, Fn in Terminal.app, or Shift in kitty).

### Color Capability

``ColorCapability`` detects what the terminal supports by inspecting environment variables (`NO_COLOR`, `COLORTERM`, `TERM`). When the capability is lower than trueColor, the ``Screen`` automatically downgrades RGB colors to palette-256 or basic-16 during ``Screen/flush()``.

## Topics

### Terminal Control

- ``Terminal/Size-swift.struct``

### Input

- ``InputEvent``
- ``KeyEvent``
- ``MouseEvent``
- ``KeyReader``

### Color

- ``ColorCapability``
