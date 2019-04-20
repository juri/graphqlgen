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

    struct Operation {
        let type: OperationType
        let name: String
    }

    struct Field {
        let name: String
        let arguments: Arguments
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
    case inlineFragment(String, children: [GraphQL])
    case history(History, children: [GraphQL])
    case leaf(String)
    case fragmentSpread(String)
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
    var stringifier: Stringifier {
        return Stringifier {
            let args = try self.arguments.stringifier.stringify()
            return #"\#(self.name)\#(args.isEmpty ? "" : "(\(args))")"#
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
            case let .inlineFragment(frag, children):
                let cstr = try GraphQL.stringify(children)
                return "... on \(escaping: frag) { \(cstr) }"
            case let .history(history, children):
                let cstr = try GraphQL.stringify(children)
                let hisstr = try history.stringifier.stringify()
                return #"history(\#(hisstr)) { \#(cstr) }"#
            case let .leaf(name):
                return name
            case let .parent(name, children):
                let cstr = try GraphQL.stringify(children)
                return "\(name) { \(cstr) }"
            case let .fragmentSpread(name):
                return "... \(name)"
            case let .field(field):
                return try field.stringifier.stringify()
            }
        }
    }
}


