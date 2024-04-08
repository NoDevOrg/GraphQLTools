import Foundation
import Pioneer
import GraphQL
import Vapor

struct Context {
    let request: Request
}

struct Resolver: ChatResolver {
    let pubsub = AsyncPubSub()

    func history(context: Context, args: ChatSchema.HistoryArguments) async throws -> [ChatSchema.Message] {
        messageHistory[args.room] ?? []
    }

    func messageCount(context: Context, args: ChatSchema.MessageCountArguments) async throws -> Int {
        messageHistory[args.room]?.count ?? 0
    }

    func sendMessage(context: Context, args: ChatSchema.SendMessageArguments) async throws -> ChatSchema.Message {
        let message = ChatSchema.Message(id: ID(uuid: UUID()), body: args.message, recieved: Date.now)
        var messages = messageHistory[args.room] ?? []
        messages.append(message)
        messageHistory[args.room] = messages
        await pubsub.publish(for: args.room, payload: message)
        return message
    }
    
    func messages(context: Context, args: ChatSchema.MessagesArguments) async throws -> EventStream<ChatSchema.Message> {
        pubsub
            .asyncStream(for: args.room)
            .toEventStream()
    }
    
    func message(context: Context, key: ChatSchema.Message.Key) async throws -> ChatSchema.Message? {
        messageHistory.values.flatMap { $0 }.first { $0.id == key.id }
    }
}
