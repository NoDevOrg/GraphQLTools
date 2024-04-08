import Foundation

extension String {
    var capitalizeFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
