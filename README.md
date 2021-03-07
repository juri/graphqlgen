# GraphQLer

[![Swift 5.3](https://img.shields.io/badge/swift-5.3-red.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-Apache%202-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
[![Twitter](https://img.shields.io/badge/twitter-@juripakaste-brightgreen.svg)](http://twitter.com/juripakaste)

GraphQLer is a Swift library for generating [GraphQL] documents (i.e. things you can send to a server.) It follows the [June 2018 spec]. It does not do networking, data binding, or parsing.

It's a pure Swift library with no dependencies beyond the standard library, so it should be usable in any environment where you can use Swift.

[GraphQL]: https://graphql.org
[June 2018 spec]: https://graphql.github.io/graphql-spec/June2018/

## Usage

For details about the API, see the [source] or [docs].

GraphQLer implements a straightforward mapping from the types in GraphQL specs to Swift types. The types are the same you'll find in the spec: Document, ExecutableDefinition, Operation, Field, Selection, SelectionSet, etc. This means that it should be easy enough if you know the format, but it can be verbose. You may want to add some layers on top of it to facilitate the use of the API you need.

Using the GraphQLer types and convenience methods, you could write something like this:

```swift
import GraphQLer
let gql = Document(definitions: [
    .query([
        .field(named: "repository", arguments: ["owner": "juri", "name": "graphqler"], selections: [
            .inlineFragment(on: "Repository", selections: [
                .field(named: "defaultBranchRef", selections: [
                    .field(named: "target", selections: [
                        .inlineFragment(on: "Commit", selections: [
                            .field(named: "history", arguments: ["first": 10], selections: [
                                .field(named: "edges", selections: [
                                    .field(named: "node", selections: [
                                        .inlineFragment(on: "Commit", selections: [
                                            "committedDate",
                                            "message"
                                        ])
                                    ])
                                ])
                            ])
                        ])
                    ])
                ])
            ])
        ])
    ])
])
let str = try gql.compactString()
```

If you're building a lot of different GraphQL documents, it's probably a good idea to add some helpers for the things you care about. If you do it with extensions, you get autocompletion support in Xcode:

```swift
import GraphQLer

/* extensions */

let gql = Document(definitions: [
    .query([
        .repository(owner: "juri", name: "graphqler", selections: [
            .inlineFragment(.onRepository([
                .defaultBranchRef([
                    .target([
                        .inlineFragment(.onCommit([
                            .history(first: 10, selections: [
                                .edges([
                                    .node([
                                        .inlineFragment(.onCommit([
                                            .committedDate,
                                            .message,
                                            ]))
                                        ])
                                    ])
                                ])
                            ]))
                        ])
                    ])
                ]))
            ])
        ])
    ])
let str = try gql.compactString()
```

You can try running these examples yourself in the included Xcode playgrounds. If you open `Package.swift` in Xcode, you should also see the playgrounds.

[source]: https://github.com/juri/graphqler
[docs]: https://juri.github.io/graphqler/
