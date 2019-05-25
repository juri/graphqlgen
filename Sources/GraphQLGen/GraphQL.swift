//
//  GraphQL.swift
//  GraphQLGen
//
//  Created by Juri Pakaste on 17/04/2019.
//

/// `GraphQL` represents an element in a GraphQL document.
///
/// `GraphQL` is a nested enum where the payload of each case is represented by a nested struct.
public indirect enum GraphQL {
    /// A name matching `/[_A-Za-z][_0-9A-Za-z]*/`.
    ///
    /// - SeeAlso: [2.1.9 Names](https://graphql.github.io/graphql-spec/June2018/#sec-Names)
    public struct Name {
        public struct BadValue: Error {
            public let value: String
        }

        public let value: String

        public init?(check value: String) {
            guard validateName(value) else { return nil }
            self.value = value
        }

        public init(value: String) {
            self.value = value
        }
    }

    /// An operation.
    ///
    /// - SeeAlso: [2.3 Operations](https://graphql.github.io/graphql-spec/June2018/#sec-Language.Operations)
    public struct Operation {
        public let type: OperationType
        public let name: Name?
        public let selectionSet: SelectionSet
    }

    /// The type of an `Operation`.
    ///
    /// - SeeAlso: [2.3 Operations](https://graphql.github.io/graphql-spec/June2018/#sec-Language.Operations)
    public enum OperationType: String {
        case query
        case mutation
        case subscription
    }

    /// One selection in a `SelectionSet`.
    ///
    /// - SeeAlso: [2.4 Selection Sets](https://graphql.github.io/graphql-spec/June2018/#sec-Selection-Sets)
    public enum Selection {
        case field(Field)
        case inlineFragment(InlineFragment)
        case fragmentSpread(FragmentSpread)
    }

    /// A list of selections.
    ///
    /// - SeeAlso: [2.4 Selection Sets](https://graphql.github.io/graphql-spec/June2018/#sec-Selection-Sets)
    public struct SelectionSet {
        public let selections: [Selection]
    }

    /// A field.
    ///
    /// - SeeAlso: [2.5 Fields](https://graphql.github.io/graphql-spec/June2018/#sec-Language.Fields)
    /// - SeeAlso: [2.7 Field Alias](https://graphql.github.io/graphql-spec/June2018/#sec-Field-Alias)
    public struct Field {
        public let alias: Name?
        public let name: Name
        public let arguments: Arguments
        public let selectionSet: SelectionSet
    }

    /// Arguments.
    ///
    /// - SeeAlso: [2.6 Arguments](https://graphql.github.io/graphql-spec/June2018/#sec-Language.Arguments)
    public struct Arguments {
        public let args: [(Name, Any)]

        public init(_ args: [(Name, Any)]) {
            self.args = args
        }
    }

    /// Fragment name.
    ///
    /// - SeeAlso: [2.8 Fragments](https://graphql.github.io/graphql-spec/June2018/#sec-Language.Fragments)
    public struct FragmentName {
        public struct BadValue: Error {
            public let value: String
        }

        public let value: String

        public init?(check value: String) {
            guard validateFragmentName(value) else { return nil }
            self.value = value
        }

        public init(value: String) {
            self.value = value
        }
    }

    /// A fragment spread.
    ///
    /// - SeeAlso: [2.8 Fragments](https://graphql.github.io/graphql-spec/June2018/#sec-Language.Fragments)
    public struct FragmentSpread {
        public let name: FragmentName
    }

    /// An inline fragment.
    ///
    /// - SeeAlso: [2.8.2 Inline Fragments](https://graphql.github.io/graphql-spec/June2018/#sec-Inline-Fragments)
    public struct InlineFragment {
        public let namedType: String
        public let selectionSet: SelectionSet
    }

    case operation(Operation)
    case inlineFragment(InlineFragment)
    case fragmentSpread(FragmentSpread)
    case field(Field)

    /// Initialize a `GraphQL` as an `operation` with the provided content.
    public init(_ op: Operation) {
        self = .operation(op)
    }

    /// Initialize a `GraphQL` as an `inlineFragment` with the provided content.
    public init(_ inlineFrag: InlineFragment) {
        self = .inlineFragment(inlineFrag)
    }

    /// Initialize a `GraphQL` as a `fragmentSpread` with the provided content.
    public init(_ fragmentSpread: FragmentSpread) {
        self = .fragmentSpread(fragmentSpread)
    }

    /// Initialize a `GraphQL` as a `field` with the provided content.
    public init(_ field: Field) {
        self = .field(field)
    }

    /// Retuns a compact string representation using `Stringifier.compact(_:)`.
    public func compactString() throws -> String {
        return try Stringifier.compact.stringify(self)
    }

    public static func escape(_ string: String) -> String {
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

    public static func encodePair(key: String, value: Any) throws -> String {
        let encodedValue = try stringifyArgument(value: value)
        return "\(key): \(encodedValue)"
    }

    /// Constructs a `GraphQL.Operation` with type `query`.
    public static func query(_ name: String, _ selections: [GraphQL.Selection]) -> GraphQL.Operation? {
        return GraphQL.Operation(type: .query, name: name, selections: selections)
    }

    /// Constructs a `GraphQL.Operation` with type `query`.
    public static func query(_ selections: [GraphQL.Selection]) -> GraphQL.Operation {
        return .init(type: .query, selections: selections)
    }
}

extension GraphQL.Name: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value: value)
    }
}

extension GraphQL.FragmentName: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value: value)
    }
}

extension GraphQL.Operation {
    public init(type: GraphQL.OperationType, selections: [GraphQL.Selection] = []) {
        self.init(type: type, name: nil, selectionSet: .init(selections: selections))
    }

    public init?(type: GraphQL.OperationType, name: String, selections: [GraphQL.Selection] = []) {
        self.init(type: type, name: GraphQL.Name(value: name), selectionSet: .init(selections: selections))
    }
}

extension GraphQL.SelectionSet: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: GraphQL.Selection...) {
        self.init(selections: elements)
    }
}

extension GraphQL.SelectionSet {
    public init(selectionNames: [String]) {
        self.init(selections: selectionNames.map { GraphQL.Selection.field(.init(name: $0)) })
    }
}

extension GraphQL.Field {
    public init(
        name: GraphQL.Name,
        arguments: GraphQL.Arguments = .init(),
        selectionSet: GraphQL.SelectionSet = [])
    {
        self.init(alias: nil, name: name, arguments: arguments, selectionSet: selectionSet)
    }

    public init(
        alias: GraphQL.Name? = nil,
        name: GraphQL.Name,
        arguments: GraphQL.Arguments = .init(),
        selections: [GraphQL.Selection] = [])
    {
        self.init(alias: alias, name: name, arguments: arguments, selectionSet: .init(selections: selections))
    }

    public init(
        alias: String? = nil,
        name: String,
        arguments: GraphQL.Arguments = .init(),
        selections: [GraphQL.Selection] = [])
    {
        self.init(
            alias: alias.map(GraphQL.Name.init(value:)),
            name: GraphQL.Name(value: name),
            arguments: arguments,
            selectionSet: .init(selections: selections))
    }
}

private func stringifyArgument(value: Any) throws -> String {
    switch value {
    case let s as String:
        return normalStringStringify(s)
    case let i as Int:
        return normalIntStringify(i)
    case let f as Float:
        return normalFloatStringify(f)
    case let d as Double:
        return normalDoubleStringify(d)
    case let b as Bool:
        return normalBoolStringify(b)
    case let dict as [String: Any]:
        return try compactDictStringify(dict)
    case let arr as [Any]:
        return try compactArrayStringify(arr)
    case let args as GraphQL.Arguments:
        let formatted = try compactArgsStringify(a: args)
        return "{\(formatted)}"
    default:
        throw GraphQLTypeError(message: "Unsupported type of \(value): \(type(of: value))")
    }
}

private func stringifyArgument(name: GraphQL.Name, value: Any) throws -> String {
    let vstr = try stringifyArgument(value: value)
    let nstr = try normalNameStringify(name)
    return "\(nstr): \(vstr)"
}

public struct GraphQLTypeError: Error {
    public let message: String
}

extension GraphQL.Arguments: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Any)...) {
        self.init(elements.map { (GraphQL.Name(value: $0.0), $0.1) })
    }
}

extension GraphQL.FragmentSpread: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(name: GraphQL.FragmentName(value: value))
    }
}

// MARK: - Stringification

/// `Stringifier` is a protocol witness for stringifying a `GraphQL`.
/// There are implementations for the various structures as static properties
/// in the appropriately typed extensions.
public struct Stringifier<A> {
    public var stringify: (A) throws -> String
}

public extension Stringifier where A == String {
    static let normal = Stringifier(stringify: normalStringStringify)
}

public extension Stringifier where A == GraphQL {
    static let compact = Stringifier(stringify: compactGraphQLStringify)
}

public extension Stringifier where A == GraphQL.Name {
    static let normal = Stringifier(stringify: normalNameStringify)
}

public extension Stringifier where A == GraphQL.Arguments {
    static let compact = Stringifier(stringify: compactArgsStringify)
}

public extension Stringifier where A == GraphQL.Field {
    static let compact = Stringifier(stringify: compactFieldStringify)
}

public extension Stringifier where A == GraphQL.FragmentName {
    static let normal = Stringifier(stringify: normalFragmentNameStringify)
}

public extension Stringifier where A == GraphQL.FragmentSpread {
    static let normal = Stringifier(stringify: normalFragmentSpreadStringify)
}

public extension Stringifier where A == GraphQL.InlineFragment {
    static let compact = Stringifier(stringify: compactInlineFragmentStringify)
}

public extension Stringifier where A == GraphQL.Operation {
    static let compact = Stringifier(stringify: compactOpStringify)
}

public extension Stringifier where A == GraphQL.Selection {
    static let compact = Stringifier(stringify: compactSelectionStringify)
}

public extension Stringifier where A == GraphQL.SelectionSet {
    static let compact = Stringifier(stringify: compactSelSetStringify)
}

// MARK: -

private func normalStringStringify(_ s: String) -> String {
    return #""\#(GraphQL.escape(s))""#
}

private func normalIntStringify(_ i: Int) -> String {
    return "\(i)"
}

private func normalFloatStringify(_ f: Float) -> String {
    return "\(f)"
}

private func normalDoubleStringify(_ d: Double) -> String {
    return "\(d)"
}

private func normalBoolStringify(_ b: Bool) -> String {
    return "\(b)"
}

private func compactDictStringify(_ d: [String: Any]) throws -> String {
    let encodedPairs = try d.map(GraphQL.encodePair(key:value:))
    return #"{\#(encodedPairs.joined(separator: " "))}"#
}

private func compactArrayStringify(_ a: [Any]) throws -> String {
    let encodedValues = try a.map(stringifyArgument(value:))
    return #"[\#(encodedValues.joined(separator: " "))]"#
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

private func normalNameStringify(_ n: GraphQL.Name) throws -> String {
    guard validateName(n.value) else { throw GraphQL.Name.BadValue(value: n.value) }
    return n.value
}

private func compactArgsStringify(a: GraphQL.Arguments) throws -> String {
    let args = try a.args.map(stringifyArgument(name:value:))
    return args.joined(separator: " ")
}

private func compactFieldStringify(field: GraphQL.Field) throws -> String {
    let args = try Stringifier.compact.stringify(field.arguments)
    let name = try Stringifier.normal.stringify(field.name)
    let aliasPrefix = try field.alias.map { (try Stringifier.normal.stringify($0) + ": ") } ?? ""
    let selections = field.selectionSet.selections.isEmpty
        ? ""
        : " " + (try Stringifier.compact.stringify(field.selectionSet))
    return #"\#(aliasPrefix)\#(name)\#(args.isEmpty ? "" : "(\(args))")\#(selections)"#
}

private func normalFragmentNameStringify(_ n: GraphQL.FragmentName) throws -> String {
    guard validateFragmentName(n.value) else { throw GraphQL.FragmentName.BadValue(value: n.value) }
    return n.value
}

private func normalFragmentSpreadStringify(frag: GraphQL.FragmentSpread) throws -> String {
    let name = try Stringifier.normal.stringify(frag.name)
    return "... \(name)"
}

private func compactOpStringify(op: GraphQL.Operation) throws -> String {
    let name = try op.name.map { " " + (try Stringifier.normal.stringify($0)) } ?? ""
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

private let nameHeadChars: Set<Character> = ["_", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
private let digits: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
private let nameRestChars = nameHeadChars.union(digits)

private func validateName(_ value: String) -> Bool {
    guard
        let first = value.first,
        nameHeadChars.contains(first),
        value.dropFirst().allSatisfy(nameRestChars.contains)
    else { return false }
    return true
}

private func validateFragmentName(_ value: String) -> Bool {
    return validateName(value) && value != "on"
}
