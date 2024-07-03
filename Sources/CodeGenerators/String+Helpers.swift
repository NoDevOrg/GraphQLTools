import Foundation

extension String {
    public var capitalizeFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
