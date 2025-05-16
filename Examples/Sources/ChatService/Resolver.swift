import Foundation
import GraphQL
import Graphiti
import Pioneer

struct Resolver {
    let pubsub = AsyncPubSub()
}

// At minimum when you conform your resolver to the generated protocol
// you must set a typealias for the ContextType. All other functions
// have default implementations that throw an error saying the resolver
// function is not yet implemented.
extension Resolver: ChatSchema.ChatResolver {
    typealias ContextType = NoContext
}

// MARK: - Query Resolvers
extension Resolver {
    func listMessages(context: NoContext, args: ChatSchema.ListMessagesArguments) async throws -> [ChatSchema.Message] {
        Database.roomToMessages[args.room] ?? []
    }
}

// MARK: - Mutation Resolvers
extension Resolver {
    func sendMessage(context: NoContext, args: ChatSchema.SendMessageArguments) async throws -> ChatSchema.Message {
        let message = ChatSchema.Message(id: ID(uuid: UUID()), body: args.body, received: .now)
        Database.insert(message: message, room: args.room)
        await pubsub.publish(for: args.room, payload: message)
        return message
    }
}

// MARK: - Subscription Resolvers
extension Resolver {
    func listenMessages(context: NoContext, args: ChatSchema.ListenMessagesArguments) async throws -> EventStream<ChatSchema.Message> {
        pubsub
            .asyncStream(for: args.room)
            .toEventStream()
    }
}

// MARK: Message Resolver
extension ChatSchema.Message: ChatSchema.Message.Resolver {
    typealias ContextType = NoContext

    func hash(context: NoContext, args: NoArguments) async throws -> String {
        "\(body.hashValue)"
    }

    func likes(context: NoContext, args: NoArguments) async throws -> Int {
        (1...10).randomElement() ?? 0
    }
}
