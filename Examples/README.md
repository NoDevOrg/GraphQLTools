# Examples

This package contains a Chat room service and Star Wars API example that use GraphQLCodeGen for generating Graphiti code.

## ChatService

Chat service gives examples of queries, mutations, and subscriptions using Pioneer's AsyncPubSub. These are just placeholders and can be replaced with another pubsub and database layer.

## Star Wars API

This example shows how to implement the [StarWars](https://studio.apollographql.com/public/star-wars-swapi/variant/current/schema/sdl) api that Apollo uses as an example. It takes advantage of pagination, relay style connections, and object field resolvers.

A database of Star Wars characters, movies, planets, etc can be downloaded by running the provided plugin: `swift package plugin download-swapi`. This will download and parse data from swapi.dev and create a `Database.json` file inside the `StarWarsAPI` folder. Without this file querying the api will not return any results.
