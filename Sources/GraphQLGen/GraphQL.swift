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
    public typealias Name = ValidatedName<NameValidator>

    public struct ValidatedName<V: Validator> where V.Value == String {
        public struct BadValue: Error {
            public let value: String
        }

        public let value: String

        public init?(check value: String) {
            guard V.validate(value) else { return nil }
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
        public let variableDefinitions: [VariableDefinition]
        public let directives: [Directive]
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
        public let directives: [Directive]
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
    /// A name matching `/[_A-Za-z][_0-9A-Za-z]*/`, but not `on`.
    ///
    /// - SeeAlso: [2.8 Fragments](https://graphql.github.io/graphql-spec/June2018/#sec-Language.Fragments)
    public typealias FragmentName = ValidatedName<FragmentNameValidator>

    /// A fragment spread.
    ///
    /// - SeeAlso: [2.8 Fragments](https://graphql.github.io/graphql-spec/June2018/#sec-Language.Fragments)
    public struct FragmentSpread {
        public let name: FragmentName
        public let directives: [Directive]
    }

    /// A fragment definition.
    ///
    /// - SeeAlso: [2.8 Fragments](https://graphql.github.io/graphql-spec/June2018/#sec-Language.Fragments)
    public struct FragmentDefinition {
        public let name: FragmentName
        public let typeCondition: Name
        public let selectionSet: SelectionSet
    }

    /// An inline fragment.
    ///
    /// - SeeAlso: [2.8.2 Inline Fragments](https://graphql.github.io/graphql-spec/June2018/#sec-Inline-Fragments)
    public struct InlineFragment {
        public let namedType: String
        public let selectionSet: SelectionSet
    }

    /// An input object value to embed in Arguments.
    ///
    /// You'll want to use this if you care about the ordering of the fields, but otherwise a
    /// `Dictionary<GraphQL.Name, Any>` is probably easier.
    ///
    /// - SeeAlso: [2.9.8 Input Object Values](https://graphql.github.io/graphql-spec/June2018/#sec-Input-Object-Values)
    public struct ObjectValue {
        var fields: [(GraphQL.Name, Any)]
    }

    /// A variable.
    ///
    /// - SeeAlso: [2.10 Variables](https://graphql.github.io/graphql-spec/June2018/#sec-Language.Variables)
    public struct Variable {
        public let name: Name
    }

    /// A variable definition.
    ///
    /// - SeeAlso: [2.10 Variables](https://graphql.github.io/graphql-spec/June2018/#sec-Language.Variables)
    public struct VariableDefinition {
        public let variable: Variable
        public let type: TypeReference
    }

    /// A variable definition's type reference.
    ///
    /// - SeeAlso: [2.11 Type References](https://graphql.github.io/graphql-spec/June2018/#sec-Type-References)
    public indirect enum TypeReference {
        case named(Name)
        case list([TypeReference])
        case nonNull(NonNullTypeReference)
    }

    /// A non-null type reference.
    ///
    /// - SeeAlso: [2.11 Type References](https://graphql.github.io/graphql-spec/June2018/#sec-Type-References)
    public enum NonNullTypeReference {
        case named(Name)
        case list([TypeReference])
    }

    /// A directive.
    ///
    /// - SeeAlso: [2.12 Directives](https://graphql.github.io/graphql-spec/June2018/#sec-Language.Directives)
    public struct Directive {
        public let name: Name
        public let arguments: Arguments
    }

    case operation(Operation)
    case inlineFragment(InlineFragment)
    case fragmentSpread(FragmentSpread)
    case field(Field)
    case fragmentDefinition(FragmentDefinition)

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

    public init(_ fragmentDefinition: FragmentDefinition) {
        self = .fragmentDefinition(fragmentDefinition)
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
    public static func query(_ name: String, _ selections: [GraphQL.Selection]) -> GraphQL.Operation {
        return GraphQL.Operation(type: .query, name: name, selections: selections)
    }

    /// Constructs a `GraphQL.Operation` with type `query`.
    public static func query(_ selections: [GraphQL.Selection]) -> GraphQL.Operation {
        return .init(type: .query, selections: selections)
    }
}

extension GraphQL.ValidatedName: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value: value)
    }
}

extension GraphQL.Operation {
    public init(
        type: GraphQL.OperationType,
        name: String? = nil,
        variableDefinitions: [GraphQL.VariableDefinition] = [],
        directives: [GraphQL.Directive] = [],
        selections: [GraphQL.Selection] = [])
    {
        self.init(
            type: type,
            name: name.map(GraphQL.Name.init(value:)),
            variableDefinitions: variableDefinitions,
            directives: directives,
            selectionSet: .init(selections: selections))
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
        directives: [GraphQL.Directive] = [],
        selectionSet: GraphQL.SelectionSet = [])
    {
        self.init(
            alias: nil,
            name: name,
            arguments: arguments,
            directives: directives,
            selectionSet: selectionSet)
    }

    public init(
        alias: GraphQL.Name? = nil,
        name: GraphQL.Name,
        arguments: GraphQL.Arguments = .init(),
        directives: [GraphQL.Directive] = [],
        selections: [GraphQL.Selection] = [])
    {
        self.init(
            alias: alias,
            name: name,
            arguments: arguments,
            directives: directives,
            selectionSet: .init(selections: selections))
    }

    public init(
        alias: String? = nil,
        name: String,
        arguments: GraphQL.Arguments = .init(),
        directives: [GraphQL.Directive] = [],
        selections: [GraphQL.Selection] = [])
    {
        self.init(
            alias: alias.map(GraphQL.Name.init(value:)),
            name: GraphQL.Name(value: name),
            arguments: arguments,
            directives: directives,
            selectionSet: .init(selections: selections))
    }
}

public protocol Validator {
    associatedtype Value
    static func validate(_ value: Value) -> Bool
}

public struct NameValidator: Validator {
    public static func validate(_ name: String) -> Bool {
        return validateName(name)
    }
}

public struct FragmentNameValidator: Validator {
    public static func validate(_ name: String) -> Bool {
        return validateFragmentName(name)
    }
}


func stringifyArgument(value: Any) throws -> String {
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
    case let v as GraphQL.Variable:
        return try normalVariableStringify(variable: v)
    case let o as GraphQL.ObjectValue:
        return try compactObjectValueStringify(objectValue: o)
    default:
        throw GraphQLTypeError(message: "Unsupported type of \(value): \(type(of: value))")
    }
}

func stringifyArgument(name: GraphQL.Name, value: Any) throws -> String {
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
        self.init(name: GraphQL.FragmentName(value: value), directives: [])
    }
}


private let nameHeadChars: Set<Character> = ["_", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
private let digits: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
private let nameRestChars = nameHeadChars.union(digits)

func validateName(_ value: String) -> Bool {
    guard
        let first = value.first,
        nameHeadChars.contains(first),
        value.dropFirst().allSatisfy(nameRestChars.contains)
    else { return false }
    return true
}

func validateFragmentName(_ value: String) -> Bool {
    return validateName(value) && value != "on"
}
