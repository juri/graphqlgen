# GraphQLGen

[![Swift 5.0](https://img.shields.io/badge/swift-5.0-red.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-Apache%202-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
[![Twitter](https://img.shields.io/badge/twitter-@juripakaste-brightgreen.svg)](http://twitter.com/juripakaste)

GraphQLGen is a Swift library for generating [GraphQL] documents (i.e. things you can send to a server.) It follows the [June 2018 spec]. It does not do networking, data binding, or parsing.

It's a pure Swift library with no dependencies beyond the standard library, so it should be usable in any environment where you can use Swift.

[GraphQL]: https://graphql.org
[June 2018 spec]: https://graphql.github.io/graphql-spec/June2018/

## Usage

For details about the API, see the [source] or [docs].

GraphQLGen implements a straightforward mapping from the types in GraphQL specs to Swift types. The types are the same you'll find in the spec: Document, ExecutableDefinition, Operation, Field, Selection, SelectionSet, etc. This means that it should be easy enough if you know the format, but it can be verbose. You probably want to add some layers on top of it to facilitate the use of the API you need.

Using the GraphQLGen types, you could write something like this:

```swift
import GraphQLGen
let op = GraphQL.Operation(
    .init(
        type: .query,
        name: "",
        selectionSet: .init(
            selections: [.field(.init(name: "message"))]
        )
    )
)
let gql = GraphQL.operation(op)
let str = try gql.compactString()
```

To make it more compact there's some convenience methods:

```swift
import GraphQLGen
let gql = GraphQL(GraphQL.query([.field(.init(name: "message"))]))
let str = try gql.compactString()
```

However, it's probably a good idea to add some helpers for the things you care about. If you do it with extensions, you get autocompletion support in Xcode:

```swift
import GraphQLGen
extension GraphQL.Field {
    static var message = GraphQL.Field { return .init(name: "message") }
}

let gql = GraphQL(GraphQL.query([.field(.message)]))
let str = try gql.compactString()
```

[source]: https://github.com/juri/graphqlgen
[docs]: https://juri.github.io/graphqlgen/
