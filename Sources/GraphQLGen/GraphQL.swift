//
//  GraphQL.swift
//  GraphQLGen
//
//  Created by Juri Pakaste on 17/04/2019.
//

import Foundation

indirect enum GraphQL {
    enum Ref {
        case qualifiedName(String)
    }

    enum History {
        case first(Int)
        case after(String)
    }

    enum OperationType: String {
        case query
        case mutation
        case subscription
    }

    enum Selection {
        case field(Field)
        case inlineFragment(InlineFragment)
        case fragmentSpread(FragmentSpread)
    }

    struct SelectionSet {
        let selections: [Selection]
    }

    struct InlineFragment {
        let namedType: String
        let selectionSet: SelectionSet
    }

    struct FragmentSpread {
        let name: String
    }

    struct Operation {
        let type: OperationType
        let name: String
    }

    struct Field {
        let alias: String
        let name: String
        let arguments: Arguments
        let selectionSet: SelectionSet
    }

    struct Arguments {
        let args: [String: Any]

        init(_ args: [String: Any]) {
            self.args = args
        }
    }

    case operation(Operation, [GraphQL])
    case repository(owner: String, name: String, children: [GraphQL])
    case ref(Ref, children: [GraphQL])
    case inlineFragment(InlineFragment)
    case history(History, children: [GraphQL])
    case leaf(String)
    case fragmentSpread(FragmentSpread)
    case parent(String, [GraphQL])
    case field(Field)

    static func escape(_ string: String) -> String {
        let output = string.flatMap { c -> String in
            switch c {
            case "\\": return "\\\\"
            case "\"": return "\\\""
            case "\n": return "\\n"
            case "\r": return "\\r"
            default: return "\(c)"
            }
        }
        return String(output)
    }

    static func stringify(_ items: [GraphQL]) throws -> String {
        return try items.map { try $0.stringifier.stringify() }.joined(separator: " ")
    }

    static func encodePair(key: String, value: GraphQLArgumentValue) -> String {
        let encodedValue = value.asGraphQLValue()
        return "\(key): \(encodedValue)"
    }

    static func query(_ name: String, _ children: [GraphQL]) -> GraphQL {
        return .operation(.init(type: .query, name: name), children)
    }

    static func query( _ children: [GraphQL]) -> GraphQL {
        return self.query("", children)
    }
}

struct Stringifier {
    var stringify: () throws -> String
}

extension GraphQL.Operation {
    init(type: GraphQL.OperationType) {
        self.init(type: type, name: "")
    }
}

extension GraphQL.Ref {
    var stringifier: Stringifier {
        return Stringifier {
            switch self {
            case .qualifiedName(let name):
                return "qualifiedName: \"\(GraphQL.escape(name))\""
            }
        }
    }
}

extension GraphQL.History {
    var stringifier: Stringifier {
        return Stringifier {
            switch self {
            case let .first(count):
                return "first: \(count)"
            case let .after(cursor):
                return "after: \"\(GraphQL.escape(cursor))\""
            }
        }
    }
}

extension GraphQL.Selection {
    var stringifer: Stringifier {
        return Stringifier {
            switch self {
            case let .field(field):
                return try field.stringifier.stringify()
            case let .fragmentSpread(fragmentSpread):
                return try fragmentSpread.stringifier.stringify()
            case let .inlineFragment(inlineFragment):
                return try inlineFragment.stringifier.stringify()
            }
        }
    }
}

extension GraphQL.SelectionSet {
    var stringifier: Stringifier {
        return Stringifier {
            let s = try self.selections
                .map { try $0.stringifer.stringify() }
                .joined(separator: " ")
            return #"{ \#(s) }"#
        }
    }
}

extension GraphQL.SelectionSet: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: GraphQL.Selection...) {
        self.init(selections: elements)
    }
}

extension GraphQL.FragmentSpread {
    var stringifier: Stringifier {
        return Stringifier {
            return "... \(self.name)"
        }
    }
}

extension GraphQL.InlineFragment {
    var stringifier: Stringifier {
        return Stringifier {
            let cstr = try self.selectionSet.stringifier.stringify()
            let typeCondition = self.namedType.isEmpty ? "" : "... on \(self.namedType) "
            return "\(typeCondition)\(cstr)"
        }
    }
}


protocol GraphQLArgumentValue {
    func asGraphQLValue() -> String
}

extension String: GraphQLArgumentValue {
    func asGraphQLValue() -> String {
        return #""\#(GraphQL.escape(self))""#
    }
}

extension Int: GraphQLArgumentValue {
    func asGraphQLValue() -> String {
        return "\(self)"
    }
}

extension Float: GraphQLArgumentValue {
    func asGraphQLValue() -> String {
        return "\(self)"
    }
}

extension Bool: GraphQLArgumentValue {
    func asGraphQLValue() -> String {
        return "\(self)"
    }
}

extension Dictionary: GraphQLArgumentValue where Key == String, Value: GraphQLArgumentValue {
    func asGraphQLValue() -> String {
        let encodedPairs = self.map(GraphQL.encodePair(key:value:))
        return #"{\#(encodedPairs.joined(separator: " "))}"#
    }
}

extension Array: GraphQLArgumentValue where Element: GraphQLArgumentValue {
    func asGraphQLValue() -> String {
        let encodedValues = self.map { $0.asGraphQLValue() }
        return #"[\#(encodedValues.joined(separator: " "))]"#
    }
}

extension GraphQL.Field {
    init(
        name: String,
        arguments: GraphQL.Arguments = .init(),
        selectionSet: GraphQL.SelectionSet = [])
    {
        self.init(alias: "", name: name, arguments: arguments, selectionSet: selectionSet)
    }

    var stringifier: Stringifier {
        return Stringifier {
            let args = try self.arguments.stringifier.stringify()
            let aliasPrefix = self.alias.isEmpty ? "" : self.alias + ": "
            let selections = self.selectionSet.selections.isEmpty
                ? ""
                : " " + (try self.selectionSet.stringifier.stringify())
            return #"\#(aliasPrefix)\#(self.name)\#(args.isEmpty ? "" : "(\(args))")\#(selections)"#
        }
    }
}

private func stringifyArgument(value: Any) throws -> String {
    switch value {
    case let gql as GraphQLArgumentValue:
        return gql.asGraphQLValue()
    case let arr as [Any]:
        let formatted = try arr.map(stringifyArgument(value:)).joined(separator: " ")
        return #"[\#(formatted)]"#
    case let dict as [String: Any]:
        let formatted = try dict.map(stringifyArgument(key:value:)).joined(separator: " ")
        return #"{\#(formatted)}"#
    default:
        throw GraphQLTypeError()
    }
}

private func stringifyArgument(key: String, value: Any) throws -> String {
    let vstr = try stringifyArgument(value: value)
    return "\(key): \(vstr)"
}

extension GraphQL.Arguments {
    var stringifier: Stringifier {
        return Stringifier {
            let args = try self.args.map(stringifyArgument(key:value:))
            return args.joined(separator: " ")
        }
    }
}

struct GraphQLTypeError: Error {}

extension GraphQL.Arguments: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (String, Any)...) {
        self.init(Dictionary(uniqueKeysWithValues: elements))
    }
}

extension GraphQL.FragmentSpread: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.init(name: value)
    }
}

private extension String.StringInterpolation {
    mutating func appendInterpolation(escaping str: String) {
        self.appendLiteral(GraphQL.escape(str))
    }
}

extension GraphQL {
    var stringifier: Stringifier {
        return Stringifier {
            switch self {
            case let .operation(op, children):
                let cstr = try GraphQL.stringify(children)
                return #"\#(op.type)\#(!op.name.isEmpty ? " " + op.name : "") { \#(cstr) }"#
            case let .repository(owner, name, children):
                let cstr = try GraphQL.stringify(children)
                return #"repository(owner: "\#(escaping: owner)", name: "\#(escaping: name)") { \#(cstr) }"#
            case let .ref(ref, children):
                let cstr = try GraphQL.stringify(children)
                let refstr = try ref.stringifier.stringify()
                return #"ref(\#(refstr)) { \#(cstr) }"#
            case let .inlineFragment(inlineFragment):
                return try inlineFragment.stringifier.stringify()
            case let .history(history, children):
                let cstr = try GraphQL.stringify(children)
                let hisstr = try history.stringifier.stringify()
                return #"history(\#(hisstr)) { \#(cstr) }"#
            case let .leaf(name):
                return name
            case let .parent(name, children):
                let cstr = try GraphQL.stringify(children)
                return "\(name) { \(cstr) }"
            case let .fragmentSpread(fs):
                return try fs.stringifier.stringify()
            case let .field(field):
                return try field.stringifier.stringify()
            }
        }
    }
}


