import Foundation

extension String {
    var capitalizeFirst: String {
        prefix(1).uppercased() + dropFirst()
    }

    // Swift reserved keywords that require backtick escaping when used as identifiers.
    // Reference: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/lexicalstructure/#Keywords-and-Punctuation
    private static let swiftKeywords: Set<String> = [
        // Declarations
        "associatedtype", "class", "deinit", "enum", "extension", "fileprivate",
        "func", "import", "init", "inout", "internal", "let", "open", "operator",
        "private", "precedencegroup", "protocol", "public", "rethrows", "static",
        "struct", "subscript", "typealias", "var",
        // Statements
        "break", "case", "catch", "continue", "default", "defer", "do", "else",
        "fallthrough", "for", "guard", "if", "in", "repeat", "return", "switch",
        "throw", "where", "while",
        // Expressions and types
        "Any", "as", "false", "is", "nil", "self", "Self", "super", "throws",
        "true", "try",
    ]

    /// Returns the string wrapped in backticks if it is a Swift reserved keyword.
    /// Backtick-escaped identifiers are Codable-safe: Swift strips backticks from
    /// the actual identifier name, so synthesized CodingKeys use the original key.
    var escapedIfKeyword: String {
        Self.swiftKeywords.contains(self) ? "`\(self)`" : self
    }
}
