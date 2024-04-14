import Foundation

// Too lazy to set up a real database for this example
class Database {
    static var messageHistory = [String: [ChatSchema.Message]]()
}
