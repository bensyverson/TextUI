public extension Buffer {
    /// A plain-text representation of the buffer contents.
    ///
    /// Continuation cells are skipped, trailing spaces per row are trimmed,
    /// and trailing empty rows are removed. Useful for test assertions.
    var text: String {
        var rows: [String] = []
        for r in 0 ..< height {
            var row = ""
            for c in 0 ..< width {
                let cell = self[r, c]
                if cell.isContinuation { continue }
                row.append(cell.char)
            }
            rows.append(row)
        }
        // Trim trailing spaces from each row
        rows = rows.map { row in
            var s = row
            while s.last == " " {
                s.removeLast()
            }
            return s
        }
        // Trim trailing empty rows
        while rows.last?.isEmpty == true {
            rows.removeLast()
        }
        return rows.joined(separator: "\n")
    }
}
