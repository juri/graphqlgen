//
//  GraphQL.swift
//  GraphQLGen
//
//  Created by Juri Pakaste on 17/04/2019.
//

import Foundation

indirect enum GraphQL {
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
        let selectionSet: SelectionSet
    }

    struct Field {
        let alias: String
        let name: String
        let arguments: Arguments
        let selectionSet: SelectionSet
    }

    struct Arguments {
        let args: [(String, Any)]

        init(_ args: [(String, Any)]) {
            self.args = args
        }
    }

    case operation(Operation)
    case inlineFragment(InlineFragment)
    case fragmentSpread(FragmentSpread)
    case field(Field)

    func compactString() throws -> String {
        return try Stringifier.compact.stringify(self)
    }

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
        return try items.map { try Stringifier.compact.stringify($0) }.joined(separator: " ")
    }

    static func encodePair(key: String, value: GraphQLArgumentValue) throws -> String {
        let encodedValue = try value.asGraphQLValue()
        return "\(key): \(encodedValue)"
    }

    static func query(_ name: String, _ selections: [GraphQL.Selection]) -> GraphQL.Operation {
        return .init(type: .query, name: name, selections: selections)
    }

    static func query(_ selections: [GraphQL.Selection]) -> GraphQL.Operation {
        return .init(type: .query, name: "", selections: selections)
    }
}


extension GraphQL.Operation {
    init(type: GraphQL.OperationType, name: String = "", selections: [GraphQL.Selection] = []) {
        self.init(type: type, name: "", selectionSet: .init(selections: selections))
    }
}

extension GraphQL.SelectionSet: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: GraphQL.Selection...) {
        self.init(selections: elements)
    }
}

protocol GraphQLArgumentValue {
    func asGraphQLValue() throws -> String
}

extension String: GraphQLArgumentValue {
    func asGraphQLValue() throws -> String {
        return #""\#(GraphQL.escape(self))""#
    }
}

extension Int: GraphQLArgumentValue {
    func asGraphQLValue() throws -> String {
        return "\(self)"
    }
}

extension Float: GraphQLArgumentValue {
    func asGraphQLValue() throws -> String {
        return "\(self)"
    }
}

extension Bool: GraphQLArgumentValue {
    func asGraphQLValue() throws -> String {
        return "\(self)"
    }
}

extension Dictionary: GraphQLArgumentValue where Key == String, Value: GraphQLArgumentValue {
    func asGraphQLValue() throws -> String {
        let encodedPairs = try self.map(GraphQL.encodePair(key:value:))
        return #"{\#(encodedPairs.joined(separator: " "))}"#
    }
}

extension Array: GraphQLArgumentValue where Element: GraphQLArgumentValue {
    func asGraphQLValue() throws -> String {
        let encodedValues = try self.map { try $0.asGraphQLValue() }
        return #"[\#(encodedValues.joined(separator: " "))]"#
    }
}

extension GraphQL.Arguments: GraphQLArgumentValue {
    func asGraphQLValue() throws -> String {
        let encodedPairs = try self.args.map { try stringifyArgument(key: $0, value: $1) }
        return #"{\#(encodedPairs.joined(separator: " "))}"#
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

    init(
        alias: String = "",
        name: String,
        arguments: GraphQL.Arguments = .init(),
        selections: [GraphQL.Selection] = [])
    {
        self.init(alias: "", name: name, arguments: arguments, selectionSet: .init(selections: selections))
    }
}

private func stringifyArgument(value: Any) throws -> String {
    switch value {
    case let gql as GraphQLArgumentValue:
        return try gql.asGraphQLValue()
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

struct GraphQLTypeError: Error {}

extension GraphQL.Arguments: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (String, Any)...) {
        self.init(elements)
    }
}

extension GraphQL.FragmentSpread: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.init(name: value)
    }
}

// MARK: - Stringification

struct Stringifier<A> {
    var stringify: (A) throws -> String
}

extension Stringifier where A == GraphQL {
    static let compact = Stringifier(stringify: compactGraphQLStringify)
}

extension Stringifier where A == GraphQL.Arguments {
    static let compact = Stringifier(stringify: compactArgsStringify)
}

extension Stringifier where A == GraphQL.Field {
    static let compact = Stringifier(stringify: compactFieldStringify)
}

extension Stringifier where A == GraphQL.FragmentSpread {
    static let normal = Stringifier(stringify: normalFragmentSpreadStringify)
}

extension Stringifier where A == GraphQL.InlineFragment {
    static let compact = Stringifier(stringify: compactInlineFragmentStringify)
}

extension Stringifier where A == GraphQL.Operation {
    static let compact = Stringifier(stringify: compactOpStringify)
}

extension Stringifier where A == GraphQL.Selection {
    static let compact = Stringifier(stringify: compactSelectionStringify)
}

extension Stringifier where A == GraphQL.SelectionSet {
    static let compact = Stringifier(stringify: compactSelSetStringify)
}

private func compactGraphQLStringify(gql: GraphQL) throws -> String {
    switch gql {
    case let .operation(op):
        return try Stringifier.compact.stringify(op)
    case let .inlineFragment(inlineFragment):
        return try Stringifier.compact.stringify(inlineFragment)
    case let .fragmentSpread(fs):
        return try Stringifier.normal.stringify(fs)
    case let .field(field):
        return try Stringifier.compact.stringify(field)
    }
}

private func compactArgsStringify(a: GraphQL.Arguments) throws -> String {
    let args = try a.args.map(stringifyArgument(key:value:))
    return args.joined(separator: " ")
}

private func compactFieldStringify(field: GraphQL.Field) throws -> String {
    let args = try Stringifier.compact.stringify(field.arguments)
    let aliasPrefix = field.alias.isEmpty ? "" : field.alias + ": "
    let selections = field.selectionSet.selections.isEmpty
        ? ""
        : " " + (try Stringifier.compact.stringify(field.selectionSet))
    return #"\#(aliasPrefix)\#(field.name)\#(args.isEmpty ? "" : "(\(args))")\#(selections)"#
}

private func normalFragmentSpreadStringify(frag: GraphQL.FragmentSpread) throws -> String {
    return "... \(frag.name)"
}

private func compactOpStringify(op: GraphQL.Operation) throws -> String {
    let name = op.name.isEmpty ? "" : " " + op.name
    let selections = try Stringifier.compact.stringify(op.selectionSet)
    return #"\#(op.type.rawValue)\#(name) \#(selections)"#
}

private func compactInlineFragmentStringify(frag: GraphQL.InlineFragment) throws -> String {
    let cstr = try Stringifier.compact.stringify(frag.selectionSet)
    let typeCondition = frag.namedType.isEmpty ? "" : "... on \(frag.namedType) "
    return "\(typeCondition)\(cstr)"
}

private func compactSelectionStringify(sel: GraphQL.Selection) throws -> String {
    switch sel {
    case let .field(field):
        return try Stringifier.compact.stringify(field)
    case let .fragmentSpread(fragmentSpread):
        return try Stringifier.normal.stringify(fragmentSpread)
    case let .inlineFragment(inlineFragment):
        return try Stringifier.compact.stringify(inlineFragment)
    }
}

private func compactSelSetStringify(selSet: GraphQL.SelectionSet) throws -> String {
    let selections: [GraphQL.Selection] = selSet.selections
    let stringifiedSelections: [String] = try selections.map { (s: GraphQL.Selection) throws -> String in try Stringifier.compact.stringify(s) }
    let joined: String = stringifiedSelections.joined(separator: " ")
    return #"{ \#(joined) }"#
}
