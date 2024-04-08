import Foundation
import Pioneer
import GraphQL
import Vapor

struct Context {
    let request: Request
}

extension ChatSchema {
    typealias DateTime = Foundation.Date
}

struct Resolver: ChatResolver {
    let pubsub = AsyncPubSub()

    func history(context: Context, args: ChatSchema.HistoryArguments) async throws -> [ChatSchema.Message] {
        messageHistory[args.room] ?? []
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
