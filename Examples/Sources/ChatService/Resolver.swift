import Foundation
import Pioneer
import GraphQL

struct Resolver {
    let pubsub = AsyncPubSub()
}

extension Resolver: ChatSchema.ChatResolver {
    func history(context: Context, args: ChatSchema.HistoryArguments) async throws -> [ChatSchema.Message] {
        Database.messageHistory[args.room] ?? []
    }

    func sendMessage(context: Context, args: ChatSchema.SendMessageArguments) async throws -> ChatSchema.Message {
        let message = ChatSchema.Message(id: ID(uuid: UUID()), body: args.message, received: Date.now)
        var messages = Database.messageHistory[args.room] ?? []
        messages.insert(message, at: 0)
        Database.messageHistory[args.room] = messages
        await pubsub.publish(for: args.room, payload: message)
        return message
    }
    
    func messages(context: Context, args: ChatSchema.MessagesArguments) async throws -> EventStream<ChatSchema.Message> {
        pubsub
            .asyncStream(for: args.room)
            .toEventStream()
    }
    
    func message(context: Context, key: ChatSchema.Message.Key) async throws -> ChatSchema.Message? {
        Database.messageHistory.values.flatMap { $0 }.first { $0.id == key.id }
    }
}
