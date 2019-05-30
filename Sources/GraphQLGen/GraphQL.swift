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
    /// A GraphQL operation.
    case operation(Operation)

    /// A GraphQL inline fragment.
    case inlineFragment(InlineFragment)

    /// A GraphQL fragment spread.
    case fragmentSpread(FragmentSpread)

    /// A GraphQL field.
    case field(Field)

    /// A GraphQL fragment definition.
    case fragmentDefinition(FragmentDefinition)

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

        public init(
            type: OperationType,
            name: Name? = nil,
            variableDefinitions: [VariableDefinition] = [],
            directives: [Directive] = [],
            selectionSet: SelectionSet)
        {
            self.type = type
            self.name = name
            self.variableDefinitions = variableDefinitions
            self.directives = directives
            self.selectionSet = selectionSet
        }
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

        public init(selections: [Selection]) {
            self.selections = selections
        }

        public static let empty = SelectionSet(selections: [])
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

        public init(
            alias: Name? = nil,
            name: Name,
            arguments: Arguments = .empty,
            directives: [Directive] = [],
            selectionSet: SelectionSet = .empty)
        {
            self.alias = alias
            self.name = name
            self.arguments = arguments
            self.directives = directives
            self.selectionSet = selectionSet
        }
    }

    /// Arguments.
    ///
    /// - SeeAlso: [2.6 Arguments](https://graphql.github.io/graphql-spec/June2018/#sec-Language.Arguments)
    public struct Arguments {
        public let args: [(Name, Any)]

        public init(args: [(Name, Any)]) {
            self.args = args
        }

        public static let empty = Arguments([])
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

        public init(
            name: FragmentName,
            directives: [Directive] = [])
        {
            self.name = name
            self.directives = directives
        }
    }

    /// A fragment definition.
    ///
    /// - SeeAlso: [2.8 Fragments](https://graphql.github.io/graphql-spec/June2018/#sec-Language.Fragments)
    public struct FragmentDefinition {
        public let name: FragmentName
        public let typeCondition: Name
        public let directives: [Directive]
        public let selectionSet: SelectionSet

        public init(
            name: FragmentName,
            typeCondition: Name,
            directives: [Directive] = [],
            selectionSet: SelectionSet)
        {
            self.name = name
            self.typeCondition = typeCondition
            self.directives = directives
            self.selectionSet = selectionSet
        }
    }

    /// An inline fragment.
    ///
    /// - SeeAlso: [2.8.2 Inline Fragments](https://graphql.github.io/graphql-spec/June2018/#sec-Inline-Fragments)
    public struct InlineFragment {
        public let namedType: String
        public let selectionSet: SelectionSet

        public init(
            namedType: String,
            selectionSet: SelectionSet)
        {
            self.namedType = namedType
            self.selectionSet = selectionSet
        }
    }

    /// An input object value to embed in Arguments.
    ///
    /// You'll want to use this if you care about the ordering of the fields, but otherwise a
    /// `Dictionary<GraphQL.Name, Any>` is probably easier.
    ///
    /// - SeeAlso: [2.9.8 Input Object Values](https://graphql.github.io/graphql-spec/June2018/#sec-Input-Object-Values)
    public struct ObjectValue {
        public let fields: [(GraphQL.Name, Any)]

        public init(fields: [(GraphQL.Name, Any)]) {
            self.fields = fields
        }
    }

    /// A variable.
    ///
    /// - SeeAlso: [2.10 Variables](https://graphql.github.io/graphql-spec/June2018/#sec-Language.Variables)
    public struct Variable {
        public let name: Name

        public init(name: Name) {
            self.name = name
        }
    }

    /// A variable definition.
    ///
    /// - SeeAlso: [2.10 Variables](https://graphql.github.io/graphql-spec/June2018/#sec-Language.Variables)
    public struct VariableDefinition {
        public let variable: Variable
        public let type: TypeReference

        public init(
            variable: Variable,
            type: TypeReference)
        {
            self.variable = variable
            self.type = type
        }
    }

    /// A variable definition's type reference.
    ///
    /// The type reference can be a single `Name`, a list of `TypeReference`s,
    /// or a non-null version of those options, wrapped in a `NonNullTypeReference`.
    ///
    /// - SeeAlso: [2.11 Type References](https://graphql.github.io/graphql-spec/June2018/#sec-Type-References)
    public indirect enum TypeReference {
        case named(Name)
        case list([TypeReference])
        case nonNull(NonNullTypeReference)
    }

    /// A non-null type reference.
    ///
    /// A non-null type reference can be either a single `Name` or a list of `TypeReference`s.
    ///
    /// - SeeAlso: [2.11 Type References](https://graphql.github.io/graphql-spec/June2018/#sec-Type-References)
    public enum NonNullTypeReference {
        case named(Name)
        case list([TypeReference])
    }

    /// A directive.
    ///
    /// A directive has a name and arguments.
    ///
    /// - SeeAlso: [2.12 Directives](https://graphql.github.io/graphql-spec/June2018/#sec-Language.Directives)
    public struct Directive {
        public let name: Name
        public let arguments: Arguments

        public init(
            name: Name,
            arguments: Arguments)
        {
            self.name = name
            self.arguments = arguments
        }
    }

    /// Initialize a `GraphQL` as a `GraphQL.operation` with the provided content.
    public init(_ op: Operation) {
        self = .operation(op)
    }

    /// Initialize a `GraphQL` as an `GraphQL.inlineFragment` with the provided content.
    public init(_ inlineFrag: InlineFragment) {
        self = .inlineFragment(inlineFrag)
    }

    /// Initialize a `GraphQL` as a `GraphQL.fragmentSpread` with the provided content.
    public init(_ fragmentSpread: FragmentSpread) {
        self = .fragmentSpread(fragmentSpread)
    }

    /// Initialize a `GraphQL` as a `GraphQL.fragmentDefinition` with the provided content.
    public init(_ fragmentDefinition: FragmentDefinition) {
        self = .fragmentDefinition(fragmentDefinition)
    }

    /// Initialize a `GraphQL` as a `GraphQL.field` with the provided content.
    public init(_ field: Field) {
        self = .field(field)
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
        return GraphQL.Operation(type: .query, name: GraphQL.Name(value: name), selections: selections)
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
        name: GraphQL.Name? = nil,
        variableDefinitions: [GraphQL.VariableDefinition] = [],
        directives: [GraphQL.Directive] = [],
        selections: [GraphQL.Selection] = [])
    {
        self.init(
            type: type,
            name: name,
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
    public init(_ selections: [GraphQL.Selection]) {
        self.init(selections: selections)
    }

    public init(selectionNames: [String]) {
        self.init(selections: selectionNames.map { GraphQL.Selection.field(.init(name: $0)) })
    }
}

extension GraphQL.ObjectValue {
    public init(_ fields: [(GraphQL.Name, Any)]) {
        self.init(fields: fields)
    }
}

extension GraphQL.Variable {
    public init(_ name: GraphQL.Name) {
        self.init(name: name)
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
    public init(_ args: [(GraphQL.Name, Any)]) {
        self.init(args: args)
    }

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
