import Foundation
import GraphQLer
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

extension Selection {
    static func repository(owner: String, name: String, selections: [Selection]) -> Selection {
        return .field(
            .init(name: "repository", arguments: ["owner": owner, "name": name], selections: selections))
    }

    static func defaultBranchRef(_ selections: [Selection]) -> Selection {
        return .field(.init(name: "defaultBranchRef", selections: selections))
    }

    static func target(_ selections: [Selection]) -> Selection {
        return .field(.init(name: "target", selections: selections))
    }

    static func history(first: Int, selections: [Selection]) -> Selection {
        return .field(.init(name: "history", arguments: ["first": first], selections: selections))
    }

    static func edges(_ selections: [Selection]) -> Selection {
        return .field(.init(name: "edges", selections: selections))
    }

    static func node(_ selections: [Selection]) -> Selection {
        return .field(.init(name: "node", selections: selections))
    }

    static var committedDate: Selection {
        return .field(.init(name: "committedDate"))
    }

    static var message: Selection {
        return .field(.init(name: "message"))
    }
}

extension InlineFragment {
    static func onRepository(_ selections: [Selection]) -> InlineFragment {
        return InlineFragment(namedType: "Repository", selectionSet: .init(selections))
    }

    static func onCommit(_ selections: [Selection]) -> InlineFragment {
        return InlineFragment(namedType: "Commit", selectionSet: .init(selections))
    }
}

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

guard !token.isEmpty else {
    preconditionFailure("You need to add a GitHub auth token to Networking.swift")
}
let gqlString = try gql.compactString()
query(gqlString) { result in
    print("networking result: \(result)")
    PlaygroundPage.current.finishExecution()
}
