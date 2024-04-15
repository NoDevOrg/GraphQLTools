import Foundation

// This is a placeholder for a real database just for the demo application.
struct Database {
    static var roomToMessages = [String: [ChatSchema.Message]]()

    static func insert(message: ChatSchema.Message, room: String) {
        var messages = roomToMessages[room] ?? []
        messages.insert(message, at: 0)
        roomToMessages[room] = messages
    }
}
