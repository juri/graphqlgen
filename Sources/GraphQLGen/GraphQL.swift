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
        return try items.map { try $0.stringifier.stringify() }.joined(separator: " ")
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

struct Stringifier {
    var stringify: () throws -> String
}

extension GraphQL.Operation {
    init(type: GraphQL.OperationType, name: String = "", selections: [GraphQL.Selection] = []) {
        self.init(type: type, name: "", selectionSet: .init(selections: selections))
    }

    var stringifier: Stringifier {
        return Stringifier {
            let name = self.name.isEmpty ? "" : " " + self.name
            let selections = try self.selectionSet.stringifier.stringify()
            return #"\#(self.type.rawValue)\#(name) \#(selections)"#
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

    init(
        alias: String = "",
        name: String,
        arguments: GraphQL.Arguments = .init(),
        selections: [GraphQL.Selection] = [])
    {
        self.init(alias: "", name: name, arguments: arguments, selectionSet: .init(selections: selections))
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

extension GraphQL {
    var stringifier: Stringifier {
        return Stringifier {
            switch self {
            case let .operation(op):
                return try op.stringifier.stringify()
            case let .inlineFragment(inlineFragment):
                return try inlineFragment.stringifier.stringify()
            case let .fragmentSpread(fs):
                return try fs.stringifier.stringify()
            case let .field(field):
                return try field.stringifier.stringify()
            }
        }
    }
}


