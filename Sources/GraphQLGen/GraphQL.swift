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
        let args: [String: Any]

        init(_ args: [String: Any]) {
            self.args = args
        }
    }

    case operation(Operation)
    case inlineFragment(InlineFragment)
    case fragmentSpread(FragmentSpread)
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
        return try items.map { try Stringifiers.compact.stringify($0) }.joined(separator: " ")
    }

    static func encodePair(key: String, value: GraphQLArgumentValue) -> String {
        let encodedValue = value.asGraphQLValue()
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

// MARK: - Stringification

struct Stringifier<A> {
    var stringify: (A) throws -> String
}

enum Stringifiers {
    static let compact = Stringifier(stringify: compactGraphQLStringify)
    static let compactArgs = Stringifier(stringify: compactArgsStringify)
    static let compactField = Stringifier(stringify: compactFieldStringify)
    static let normal = Stringifier(stringify: normalFragmentSpreadStringify)
    static let compactInlineFragment = Stringifier(stringify: compactInlineFragmentStringify)
    static let compactOp = Stringifier(stringify: compactOpStringify)
    static let compactSelection = Stringifier(stringify: compactSelectionStringify)
    static let compactSelSet = Stringifier(stringify: compactSelSetStringify)
}

private func compactGraphQLStringify(gql: GraphQL) throws -> String {
    switch gql {
    case let .operation(op):
        return try Stringifiers.compactOp.stringify(op)
    case let .inlineFragment(inlineFragment):
        return try Stringifiers.compactInlineFragment.stringify(inlineFragment)
    case let .fragmentSpread(fs):
        return try Stringifiers.normal.stringify(fs)
    case let .field(field):
        return try Stringifiers.compactField.stringify(field)
    }
}

private func compactArgsStringify(a: GraphQL.Arguments) throws -> String {
    let args = try a.args.map(stringifyArgument(key:value:))
    return args.joined(separator: " ")
}

private func compactFieldStringify(field: GraphQL.Field) throws -> String {
    let args = try Stringifiers.compactArgs.stringify(field.arguments)
    let aliasPrefix = field.alias.isEmpty ? "" : field.alias + ": "
    let selections = field.selectionSet.selections.isEmpty
        ? ""
        : " " + (try Stringifiers.compactSelSet.stringify(field.selectionSet))
    return #"\#(aliasPrefix)\#(field.name)\#(args.isEmpty ? "" : "(\(args))")\#(selections)"#
}

private func normalFragmentSpreadStringify(frag: GraphQL.FragmentSpread) throws -> String {
    return "... \(frag.name)"
}

private func compactOpStringify(op: GraphQL.Operation) throws -> String {
    let name = op.name.isEmpty ? "" : " " + op.name
    let selections = try Stringifiers.compactSelSet.stringify(op.selectionSet)
    return #"\#(op.type.rawValue)\#(name) \#(selections)"#
}

private func compactInlineFragmentStringify(frag: GraphQL.InlineFragment) throws -> String {
    //        let cstr = "asdf"
    let cstr = try Stringifiers.compactSelSet.stringify(frag.selectionSet)
    let typeCondition = frag.namedType.isEmpty ? "" : "... on \(frag.namedType) "
    return "\(typeCondition)\(cstr)"
}

private func compactSelectionStringify(sel: GraphQL.Selection) throws -> String {
    switch sel {
    case let .field(field):
        return try Stringifiers.compactField.stringify(field)
    case let .fragmentSpread(fragmentSpread):
        return try Stringifiers.normal.stringify(fragmentSpread)
    case let .inlineFragment(inlineFragment):
        return try Stringifiers.compactInlineFragment.stringify(inlineFragment)
    }
}

private func compactSelSetStringify(selSet: GraphQL.SelectionSet) throws -> String {
//    return "foo"
    let selections: [GraphQL.Selection] = selSet.selections
    let stringifiedSelections: [String] = try selections.map { (s: GraphQL.Selection) throws -> String in try Stringifiers.compactSelection.stringify(s) }
    let joined: String = stringifiedSelections.joined(separator: " ")
//    return "asdf"
    return #"{ \#(joined) }"#

    //        let s = try selSet.selections
    //            .map { try Stringifiers.compactSelection.stringify($0) }
    //            .joined(separator: " ")
    //        return #"{ \#(s) }"#
}
