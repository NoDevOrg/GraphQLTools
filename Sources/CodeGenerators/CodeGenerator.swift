import Foundation
import SwiftProtobufPluginLibrary

protocol CodeGenerator: AnyObject {
    var printer: CodePrinter { get set }
}

enum Scope {
    case none
    case curly

    var open: String {
        return switch self {
        case .none: ""
        case .curly: "{"
        }
    }

    var close: String {
        return switch self {
        case .none: ""
        case .curly: "}"
        }
    }
}

extension CodeGenerator {
    func println(_ text: String = "", newLine: Bool = true) {
        printer.print(text)

        if newLine {
            printer.print("\n")
        }
    }

    func comment(_ text: String) {
        println("// \(text)")
    }

    func mark(_ text: String) {
        comment("MARK: - \(text)")
    }

    func indent() {
        printer.indent()
    }

    func outdent() {
        printer.outdent()
    }

    func withIndentation(body: () throws -> Void) rethrows {
        indent()
        try body()
        outdent()
    }

    func scoped(_ header: String, scope: Scope, _ body: () throws -> Void) rethrows {
        println(header + "\(scope == .curly ? " " : "")" + scope.open)
        try withIndentation(body: body)
        println(scope.close)
    }

    func looped<T>(_ objects: [T], _ body: (T) throws -> Void) rethrows {
        for (index, object) in objects.enumerated() {
            try body(object)
            if index != (objects.count - 1) {
                println()
            }
        }
    }
}
