import XCTest
@testable import GraphQLer

private extension Selection {
    static var f1: Selection { return .field(.init(name: "f1")) }
    static var f2: Selection { return .field(.init(name: "f2")) }

    static func repo(owner: String, name: String, _ selections: [Selection]) -> Selection {
        return .field(.init(name: "repository", arguments: ["owner": owner, "name": name], selections: selections))
    }
}

class NameTests: XCTestCase {
    func testNameEmpty() throws {
        XCTAssertNil(Name(check: ""))
    }

    func testNameOneValid() throws {
        XCTAssertEqual(Name(check: "a")?.value, "a")
    }

    func testNameOneInvalid() throws {
        XCTAssertNil(Name(check: "!"))
    }

    func testNameNextValid() throws {
        XCTAssertEqual(Name(check: "a1")?.value, "a1")
    }

    func testNameNextInvalid() throws {
        XCTAssertNil(Name(check: "a!"))
    }
}

class FragmentNameTests: XCTestCase {
    func testNameValid() throws {
        XCTAssertEqual(FragmentName(check: "valid")?.value, "valid")
    }

    func testNameInvalidChars() throws {
        XCTAssertNil(FragmentName(check: "🐶"))
    }

    func testNameOn() throws {
        XCTAssertNil(FragmentName(check: "on"))
    }
}

class FragmentDefinitionTests: XCTestCase {
    func testValid() throws {
        let gql = ExecutableDefinition(
            FragmentDefinition(
                name: "frag", typeCondition: "type", selectionSet: .init(selectionNames: ["sel1", "sel2"])))
        XCTAssertEqual(try gql.compactString(), "fragment frag on type { sel1 sel2 }")
    }

    func testInvalidName() throws {
        let gql = ExecutableDefinition(
            FragmentDefinition(
                name: "fr*ag", typeCondition: "type", selectionSet: .init(selectionNames: ["sel1", "sel2"])))
        XCTAssertThrowsError(try gql.compactString())
    }

    func testInvalidTypeCondition() throws {
        let gql = ExecutableDefinition(
            FragmentDefinition(
                name: "frag", typeCondition: "ty+pe", selectionSet: .init(selectionNames: ["sel1", "sel2"])))
        XCTAssertThrowsError(try gql.compactString())
    }

    func testInvalidFieldNames() throws {
        let gql = ExecutableDefinition(
            FragmentDefinition(
                name: "frag", typeCondition: "type", selectionSet: .init(selectionNames: ["sel1", "se.l2"])))
        XCTAssertThrowsError(try gql.compactString())
    }
}

class VariableDefinitionTests: XCTestCase {
    func testQueryWithVariableDefinitions() throws {
        let vdefs = [
            VariableDefinition(variable: .init(name: "var1"), type: .named("vtype1")),
            VariableDefinition(
                variable: .init(name: "var2"),
                type: .list([.named("vtype2_1"), .named("vtype2_2")])),
            VariableDefinition(variable: .init(name: "var3"), type: .nonNull(.named("vtype3")))
        ]
        let gql = ExecutableDefinition(
            Operation(type: .query, variableDefinitions: vdefs, selections: [.field(.init(name: "sel1"))]))
        XCTAssertEqual(
            try gql.compactString(),
            "query ($var1: vtype1 $var2: [vtype2_1 vtype2_2] $var3: vtype3!) { sel1 }")
    }
}

class VariableUsageTests: XCTestCase {
    func testVariableAsArgumentValue() throws {
        let gql = Field(
            name: "valid",
            arguments: [
                "foo": "bar",
                "zap": Variable(name: "zonk"),
            ],
            selectionSet: [])
        XCTAssertEqual(try gql.compactString(), #"valid(foo: "bar" zap: $zonk)"#)
    }
}

class DirectiveTests: XCTestCase {
    func testValidNoArgs() throws {
        let dir = Directive(name: "deprecated", arguments: [:])
        XCTAssertEqual(try Stringifier.compact.stringify(dir), "@deprecated")
    }

    func testValidArgs() throws {
        let dir = Directive(name: "deprecated", arguments: ["foo": "bar", "zap": "fnord"])
        XCTAssertEqual(try Stringifier.compact.stringify(dir), #"@deprecated(foo: "bar" zap: "fnord")"#)
    }

    func testInvalidName() throws {
        let dir = Directive(name: "depr!ecated", arguments: [:])
        XCTAssertThrowsError(try Stringifier.compact.stringify(dir))
    }

    func testOperationWithDirectives() throws {
        let gql = ExecutableDefinition(
            Operation(
                type: .query,
                name: nil,
                variableDefinitions: [],
                directives: [
                    .init(name: "dir1", arguments: [:]),
                    .init(name: "dir2", arguments: ["foo": "bar"]),
                ],
                selections: [.field(.init(name: "message"))]))
        XCTAssertEqual(try gql.compactString(), #"query @dir1 @dir2(foo: "bar") { message }"#)
    }

    func testFieldWithDirectives() throws {
        let gql = ExecutableDefinition(
            Operation(
                type: .query,
                name: nil,
                variableDefinitions: [],
                directives: [
                    .init(name: "dir1", arguments: [:]),
                    .init(name: "dir2", arguments: ["foo": "bar"]),
                ],
                selections: [
                    .field(
                        .init(
                            name: "message",
                            directives: [
                                Directive(name: "dir3", arguments: ["zap": "bang", "pong": "flarp"]),
                                Directive(name: "dir4", arguments: .init([])),
                            ]))
                ]))
        XCTAssertEqual(
            try gql.compactString(),
            #"query @dir1 @dir2(foo: "bar") { message @dir3(zap: "bang" pong: "flarp") @dir4 }"#)
    }

    func testFragmentSpreadWithDirectives() throws {
        let gql = FragmentSpread(
            name: "spread", directives: [
                .init(name: "skip", arguments: ["if": Variable(name: "someTest")])
            ])
        XCTAssertEqual(try Stringifier.compact.stringify(gql), "... spread @skip(if: $someTest)")
    }

    func testFragmentDefinitionWithDirectives() throws {
        let gql = ExecutableDefinition(
            FragmentDefinition(
                name: "fdef",
                typeCondition: "tcond",
                directives: [
                    .init(name: "dir1", arguments: [:]),
                    .init(name: "dir2", arguments: ["foo": "bar"]),
                ],
                selectionSet: [
                    .field(
                        .init(
                            name: "message",
                            directives: [
                                Directive(name: "dir3", arguments: ["zap": "bang", "pong": "flarp"]),
                                Directive(name: "dir4", arguments: .init([])),
                            ]))
                ]))
        XCTAssertEqual(
            try gql.compactString(),
            #"fragment fdef on tcond @dir1 @dir2(foo: "bar") { message @dir3(zap: "bang" pong: "flarp") @dir4 }"#)
    }

    func testInlineFragmentWithDirectives() throws {
        let frag = InlineFragment(
            namedType: "Zap",
            directives: [.init(name: "include", arguments: ["if": Variable(name: "expandedInfo")])],
            selections: [.field(.init(name: "firstName"))])
        XCTAssertEqual(
            try Stringifier.compact.stringify(frag),
            #"... on Zap @include(if: $expandedInfo) { firstName }"#)
    }

    func testInlineFragmentWithDirectivesWithoutName() throws {
        let frag = InlineFragment(
            namedType: nil,
            directives: [.init(name: "include", arguments: ["if": Variable(name: "expandedInfo")])],
            selections: [.field(.init(name: "firstName"))])
        XCTAssertEqual(
            try Stringifier.compact.stringify(frag),
            #"... @include(if: $expandedInfo) { firstName }"#)
    }
}

class DocumentTests: XCTestCase {
    func testDocument() throws {
        let doc = Document(definitions: [
            .query([.field(.init(name: "f1"))]),
            .fragmentDefinition(
                .init(name: "fdef", typeCondition: "TypeCond", selections: [.field(named: "f2")])),
        ])
        XCTAssertEqual(
            try doc.compactString(),
            "query { f1 } fragment fdef on TypeCond { f2 }")
    }
}

class GraphQLTests: XCTestCase {
    func testQuery() throws {
        let q = ExecutableDefinition.query([.f1, .f2])
        XCTAssertEqual(try Stringifier.compact.stringify(q), "query { f1 f2 }")
    }

    func testCompactString() throws {
        let gql = ExecutableDefinition.query([.f1, .f2])
        XCTAssertEqual(try gql.compactString(), "query { f1 f2 }")
    }

    func testOperationInit() throws {
        let gql = ExecutableDefinition.query([.f1, .f2])
        XCTAssertEqual(try Stringifier.compact.stringify(gql), "query { f1 f2 }")
    }

    func testInlineFragmentInit() throws {
        let gql = InlineFragment(namedType: "Foo", selectionSet: .init(selectionNames: ["bar", "zot"]))
        XCTAssertEqual(try Stringifier.compact.stringify(gql), "... on Foo { bar zot }")
    }

    func testFragmentSpreadInit() throws {
        let gql = FragmentSpread(name: "spread", directives: [])
        XCTAssertEqual(try Stringifier.compact.stringify(gql), "... spread")
    }

    func testFieldInit() throws {
        let gql = Field(name: "f1")
        XCTAssertEqual(try Stringifier.compact.stringify(gql), "f1")
    }

    func testRepository() throws {
        let q = ExecutableDefinition.query([.repo(owner: "o", name: "n", [.f1])])
        XCTAssertEqual(
            try Stringifier.compact.stringify(q),
            #"query { repository(owner: "o" name: "n") { f1 } }"#)
    }

    func testEscaping() throws {
        let q = ExecutableDefinition.query([.repo(owner: "o\\hello", name: "n\"world", [.f1])])
        XCTAssertEqual(
            try Stringifier.compact.stringify(q),
            #"query { repository(owner: "o\\hello" name: "n\"world") { f1 } }"#)
    }

    func testInlineFragment() throws {
        let frag = InlineFragment(
            namedType: "Commit",
            selectionSet: .init(selections: [.field(.init(name: "message"))]))
        XCTAssertEqual(
            try Stringifier.compact.stringify(frag),
            #"... on Commit { message }"#)
    }

    func testInlineFragmentWithSelectionSetInField() throws {
        let frag = InlineFragment(
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
        XCTAssertEqual(
            try Stringifier.compact.stringify(frag),
            #"... on Commit { history(first: 10) { message } }"#)
    }

    func testFragmentSpread() throws {
        let frag = FragmentSpread("frag")
        XCTAssertEqual(
            try Stringifier.compact.stringify(frag),
            #"... frag"#)
    }

    func testFieldStringValue() throws {
        let gql = Field(name: "fname", arguments: ["foo": "bar"])
        XCTAssertEqual(
            try Stringifier.compact.stringify(gql),
            #"fname(foo: "bar")"#)
    }

    func testFieldIntValue() throws {
        let gql = Field(name: "fname", arguments: ["foo": 42])
        XCTAssertEqual(
            try Stringifier.compact.stringify(gql),
            #"fname(foo: 42)"#)
    }

    func testFieldArrayValue() throws {
        let gql = Field(name: "hasArray", arguments: ["arr": [1, 2, 3]])
        XCTAssertEqual(
            try Stringifier.compact.stringify(gql),
            #"hasArray(arr: [1 2 3])"#)
    }

    func testFieldDictValue() throws {
        let gql = Field(name: "hasDict", arguments: ["d": ObjectValue(fields: [("zap", 4), ("hod", 2)])])
        XCTAssertEqual(
            try Stringifier.compact.stringify(gql),
            #"hasDict(d: {zap: 4 hod: 2})"#)
    }

    func testFieldNestedArrayValue() throws {
        let gql = Field(name: "nested", arguments: ["d": [1, "foo", [3, "bar"]]])
        XCTAssertEqual(
            try Stringifier.compact.stringify(gql),
            #"nested(d: [1 "foo" [3 "bar"]])"#)
    }

    func testFieldNestedDictValue() throws {
        let gql = Field(name: "nested", arguments: ["d": ["a": 1, "b": ["c": 3]]])
        let options = ["nested(d: {a: 1 b: {c: 3}})", "nested(d: {b: {c: 3} a: 1})"]
        XCTAssertTrue(options.contains(try Stringifier.compact.stringify(gql)))
    }

    func testFieldAlias() throws {
        let gql = Field(
            alias: "grace", name: "f", arguments: ["foo": "zap"], directives: [], selectionSet: [])
        XCTAssertEqual(
            try Stringifier.compact.stringify(gql),
            #"grace: f(foo: "zap")"#)
    }

    func testInvalidFieldName() throws {
        let gql = Field(name: "!!!")
        XCTAssertThrowsError(try gql.compactString())
    }

    func testInvalidFragmentName() throws {
        let gql = FragmentSpread(name: "?", directives: [])
        XCTAssertThrowsError(try gql.compactString())
    }

    func testInvalidFragmentNameOn() throws {
        let gql = FragmentSpread(name: "on", directives: [])
        XCTAssertThrowsError(try gql.compactString())
    }

    func testInvalidArgumentName() throws {
        let gql = Field(name: "valid", arguments: ["?": "invalid"], selectionSet: [])
        XCTAssertThrowsError(try gql.compactString())
    }

    func testEnumValue() throws {
        let gql = Field(name: "pullRequests", arguments: ["states": [EnumValue("OPEN")]])
        XCTAssertEqual(
            try Stringifier.compact.stringify(gql),
            "pullRequests(states: [OPEN])"
        )
    }
}
