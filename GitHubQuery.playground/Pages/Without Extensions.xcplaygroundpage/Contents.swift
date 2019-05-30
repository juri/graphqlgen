import Foundation
import GraphQLGen
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

let gql = Document(definitions: [
    .query([
        .field(named: "repository", arguments: ["owner": "juri", "name": "graphqlgen"], selections: [
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

guard !token.isEmpty else {
    preconditionFailure("You need to add a GitHub auth token to Networking.swift")
}
let gqlString = try gql.compactString()
query(gqlString) { result in
    print("networking result: \(result)")
    PlaygroundPage.current.finishExecution()
}
