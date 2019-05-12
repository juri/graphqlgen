import XCTest
@testable import GraphQLGen

private extension GraphQL.Selection {
    static var f1: GraphQL.Selection { return .field(.init(name: "f1")) }
    static var f2: GraphQL.Selection { return .field(.init(name: "f2")) }

    static func repo(owner: String, name: String, _ selections: [GraphQL.Selection]) -> GraphQL.Selection {
        return .field(.init(name: "repository", arguments: ["owner": owner, "name": name], selections: selections))
    }
}

class GraphQLTests: XCTestCase {
    func testQuery() throws {
        let query = GraphQL.query([.f1, .f2])
        XCTAssertEqual(try Stringifier.compact.stringify(query), "query { f1 f2 }")
    }

    func testCompactString() throws {
        let gql = GraphQL.operation(GraphQL.query([.f1, .f2]))
        XCTAssertEqual(try gql.compactString(), "query { f1 f2 }")
    }

    func testRepository() throws {
        let query = GraphQL.query([.repo(owner: "o", name: "n", [.f1])])
        XCTAssertEqual(
            try Stringifier.compact.stringify(query),
            #"query { repository(owner: "o" name: "n") { f1 } }"#)
    }

    func testEscaping() throws {
        let query = GraphQL.query([.repo(owner: "o\\hello", name: "n\"world", [.f1])])
        XCTAssertEqual(
            try Stringifier.compact.stringify(query),
            #"query { repository(owner: "o\\hello" name: "n\"world") { f1 } }"#)
    }

    func testInlineFragment() throws {
        let frag = GraphQL.inlineFragment(
            .init(
                namedType: "Commit",
                selectionSet: .init(selections: [.field(.init(name: "message"))])))
        XCTAssertEqual(
            try Stringifier.compact.stringify(frag),
            #"... on Commit { message }"#)
    }

    func testInlineFragmentWithSelectionSetInField() throws {
        let frag = GraphQL.inlineFragment(
            .init(
                namedType: "Commit",
                selectionSet: .init(
                    selections: [
                        .field(
                            .init(
                                name: "history",
                                arguments: ["first": 10],
                                selectionSet: [
                                    .field(.init(name: "message"))
                                ]
                            )
                        )
                    ]
                )
            )
        )
        XCTAssertEqual(
            try Stringifier.compact.stringify(frag),
            #"... on Commit { history(first: 10) { message } }"#)
    }

    func testFragmentSpread() throws {
        let frag = GraphQL.fragmentSpread("frag")
        XCTAssertEqual(
            try Stringifier.compact.stringify(frag),
            #"... frag"#)
    }

    func testFieldStringValue() throws {
        let gql = GraphQL.field(.init(name: "fname", arguments: ["foo": "bar"]))
        XCTAssertEqual(
            try Stringifier.compact.stringify(gql),
            #"fname(foo: "bar")"#)
    }

    func testFieldIntValue() throws {
        let gql = GraphQL.field(.init(name: "fname", arguments: ["foo": 42]))
        XCTAssertEqual(
            try Stringifier.compact.stringify(gql),
            #"fname(foo: 42)"#)
    }

    func testFieldArrayValue() throws {
        let gql = GraphQL.field(.init(name: "hasArray", arguments: ["arr": [1, 2, 3]]))
        XCTAssertEqual(
            try Stringifier.compact.stringify(gql),
            #"hasArray(arr: [1 2 3])"#)
    }

    func testFieldDictValue() throws {
        let gql = GraphQL.field(.init(name: "hasDict", arguments: ["d": GraphQL.Arguments([("zap", 4), ("hod", 2)])]))
        XCTAssertEqual(
            try Stringifier.compact.stringify(gql),
            #"hasDict(d: {zap: 4 hod: 2})"#)
    }

    func testFieldNestedArrayValue() throws {
        let gql = GraphQL.field(.init(name: "nested", arguments: ["d": [1, "foo", [3, "bar"]]]))
        XCTAssertEqual(
            try Stringifier.compact.stringify(gql),
            #"nested(d: [1 "foo" [3 "bar"]])"#)
    }

    func testFieldNestedDictValue() throws {
        let gql = GraphQL.field(.init(name: "nested", arguments: ["d": ["a": 1, "b": ["c": 3]]]))
        let options = ["nested(d: {a: 1 b: {c: 3}})", "nested(d: {b: {c: 3} a: 1})"]
        XCTAssertTrue(options.contains(try Stringifier.compact.stringify(gql)))
    }

    func testFieldAlias() throws {
        let gql = GraphQL.field(.init(alias: "grace", name: "f", arguments: ["foo": "zap"], selectionSet: []))
        XCTAssertEqual(
            try Stringifier.compact.stringify(gql),
            #"grace: f(foo: "zap")"#)
    }
}
