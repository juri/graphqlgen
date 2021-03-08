//
//  GraphQL.swift
//  GraphQLer
//
//  Created by Juri Pakaste on 17/04/2019.
//

/// `Document` represents a GraphQL document.
///
/// GraphQLer does not support type system definitions or extensions, so the only things
/// a `Document` may contain are `ExecutableDefinition`s.
///
/// - SeeAlso: [2.2 Document](https://spec.graphql.org/June2018/#sec-Language.Document)
public struct Document {
    /// The executable definitions contained by this document.
    public var definitions: [ExecutableDefinition]

    /// Initialize a new `Document`.
    public init(definitions: [ExecutableDefinition]) {
        self.definitions = definitions
    }
}

/// `ExecutableDefinition` represents an executable definition element in a GraphQL document.
///
/// - SeeAlso: [2.2 Document](https://spec.graphql.org/June2018/#sec-Language.Document)
public enum ExecutableDefinition {
    /// A GraphQL operation.
    case operation(Operation)

    /// A GraphQL fragment definition.
    case fragmentDefinition(FragmentDefinition)
}

/// A name matching `/[_A-Za-z][_0-9A-Za-z]*/`.
///
/// - SeeAlso: [2.1.9 Names](https://spec.graphql.org/June2018/#sec-Names)
public typealias Name = ValidatedName<NameValidator>

/// `ValidatedName` is a name with pluggable validation logic.
public struct ValidatedName<V: Validator> where V.Value == String {
    /// `ValidatedName` throws `BadValue` when `validateValue` is called if `value` is invalid.
    public struct BadValue: Error {
        /// The invalid value the name had.
        public let value: String
    }

    /// The value of the name.
    public let value: String

    /// Validates the input string and if it's acceptable, initializes the `ValidatedName`.
    public init?(check value: String) {
        guard V.validate(value) else { return nil }
        self.value = value
    }

    /// Initializes the `ValidatedName` without validation.
    ///
    /// Stringifying a `ValidatedName` with an invalid value will throw an exception.
    public init(value: String) {
        self.value = value
    }

    /// Return `value` or throw `BadValue` if it's invalid.
    public func validateValue() throws -> String {
        guard V.validate(self.value) else { throw BadValue(value: self.value) }
        return self.value
    }
}

/// An operation.
///
/// - SeeAlso: [2.3 Operations](https://spec.graphql.org/June2018/#sec-Language.Operations)
public struct Operation {
    /// Operation type.
    public var type: OperationType
    /// Operation name.
    public var name: Name?
    /// Variable definitions.
    public var variableDefinitions: [VariableDefinition]
    /// Directives.
    public var directives: [Directive]
    /// Selection set for this operation.
    public var selectionSet: SelectionSet

    /// Initialize a new `Operation`.
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
/// - SeeAlso: [2.3 Operations](https://spec.graphql.org/June2018/#sec-Language.Operations)
public enum OperationType: String {
    /// A read-only fetch.
    case query
    /// A write followed by a fetch.
    case mutation
    /// A  long‐lived request that fetches data in response to source events.
    case subscription
}

/// One selection in a `SelectionSet`.
///
/// - SeeAlso: [2.4 Selection Sets](https://spec.graphql.org/June2018/#sec-Selection-Sets)
public enum Selection {
    /// A discrete piece of information to select.
    case field(Field)
    /// A fragments defined inline within a selection set.
    case inlineFragment(InlineFragment)
    /// A of common repeated selection of fields to reuse.
    case fragmentSpread(FragmentSpread)
}

/// A list of selections.
///
/// - SeeAlso: [2.4 Selection Sets](https://spec.graphql.org/June2018/#sec-Selection-Sets)
public struct SelectionSet {
    /// The selections contained in this set. May be empty.
    public var selections: [Selection]

    /// Initialize a new `SelectionSet` with this list of `Selection`s.
    public init(selections: [Selection]) {
        self.selections = selections
    }

    /// An empty `SelectionSet`.
    public static let empty = SelectionSet(selections: [])
}

/// A field.
///
/// - SeeAlso: [2.5 Fields](https://spec.graphql.org/June2018/#sec-Language.Fields)
/// - SeeAlso: [2.7 Field Alias](https://spec.graphql.org/June2018/#sec-Field-Alias)
public struct Field {
    /// Define a different key to use in the response object for this field.
    public var alias: Name?
    /// Name of this field.
    public var name: Name
    /// Arguments to specify for this field.
    public var arguments: Arguments
    /// Describe alternate runtime execution and type validation behavior for this field.
    public var directives: [Directive]
    /// Select what information to include for this field.
    public var selectionSet: SelectionSet

    /// Initialize a new `Field`.
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
/// - SeeAlso: [2.6 Arguments](https://spec.graphql.org/June2018/#sec-Language.Arguments)
public struct Arguments {
    /// The name-value pairs in this argument list.
    public var args: [(Name, Any)]

    /// Initialize a new `Arguments`.
    public init(args: [(Name, Any)]) {
        self.args = args
    }

    /// Append an argument to the argument list.
    public mutating func append(name: Name, value: Any) {
        self.append(pair: (name, value))
    }

    /// Append an argument to the argument list.
    public mutating func append(pair: (Name, Value)) {
        self.args.append(pair)
    }

    /// An empty `Arguments` instance.
    public static let empty = Arguments([])
}

/// Fragment name.
///
/// A name matching `/[_A-Za-z][_0-9A-Za-z]*/`, but not `on`.
///
/// - SeeAlso: [2.8 Fragments](https://spec.graphql.org/June2018/#sec-Language.Fragments)
public typealias FragmentName = ValidatedName<FragmentNameValidator>

/// A fragment spread.
///
/// - SeeAlso: [2.8 Fragments](https://spec.graphql.org/June2018/#sec-Language.Fragments)
public struct FragmentSpread {
    public var name: FragmentName
    public var directives: [Directive]

    /// Initialize a new `FragmentSpread`.
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
/// - SeeAlso: [2.8 Fragments](https://spec.graphql.org/June2018/#sec-Language.Fragments)
public struct FragmentDefinition {
    public var name: FragmentName
    public var typeCondition: Name
    public var directives: [Directive]
    public var selectionSet: SelectionSet

    /// Initialize a new `FragmentDefinition`.
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
/// - SeeAlso: [2.8.2 Inline Fragments](https://spec.graphql.org/June2018/#sec-Inline-Fragments)
public struct InlineFragment {
    public var namedType: Name?
    public var directives: [Directive]
    public var selectionSet: SelectionSet

    /// Initialize a new `InlineFragment`.
    public init(
        namedType: Name?,
        directives: [Directive] = [],
        selectionSet: SelectionSet)
    {
        self.namedType = namedType
        self.directives = directives
        self.selectionSet = selectionSet
    }
}

/// An input object value to embed in Arguments.
///
/// You'll want to use this if you care about the ordering of the fields, but otherwise a
/// `Dictionary<Name, Any>` is probably easier.
///
/// - SeeAlso: [2.9.8 Input Object Values](https://spec.graphql.org/June2018/#sec-Input-Object-Values)
public struct ObjectValue {
    public var fields: [(Name, Any)]

    /// Initialize a new `ObjectValue`.
    public init(fields: [(Name, Any)]) {
        self.fields = fields
    }
}

/// A value of an Enum type.
///
/// Enum values are Names that are included in the document as-is without quotation.
///
/// - SeeAlso: [3.9 Enums](http://spec.graphql.org/June2018/#sec-Enums)
public struct EnumValue {
    /// The name of this enumeration value.
    public var name: Name

    /// Initialize a new `EnumValue`.
    public init(_ name: Name) {
        self.name = name
    }
}

/// A variable. Represented as `$name` in the document.
///
/// - SeeAlso: [2.10 Variables](https://spec.graphql.org/June2018/#sec-Language.Variables)
public struct Variable {
    /// The name of this variable.
    public var name: Name

    /// Initialize a new `Variable`.
    public init(name: Name) {
        self.name = name
    }
}

/// A variable definition. Represented as `$name: type` in the document.
///
/// - SeeAlso: [2.10 Variables](https://spec.graphql.org/June2018/#sec-Language.Variables)
public struct VariableDefinition {
    /// The variable to define.
    public var variable: Variable
    /// Type of the variable.
    public var type: TypeReference

    /// Initialize a new `VariableDefinition`.
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
/// - SeeAlso: [2.11 Type References](https://spec.graphql.org/June2018/#sec-Type-References)
public indirect enum TypeReference {
    /// A named type.
    case named(Name)
    /// A list of of type.
    case list([TypeReference])
    /// A non-null type.
    case nonNull(NonNullTypeReference)
}

/// A non-null type reference.
///
/// A non-null type reference can be either a single `Name` or a list of `TypeReference`s.
///
/// - SeeAlso: [2.11 Type References](https://spec.graphql.org/June2018/#sec-Type-References)
public enum NonNullTypeReference {
    /// A named non-null type.
    case named(Name)
    /// A list of non-null types.
    case list([TypeReference])
}

/// A directive.
///
/// A directive has a name and arguments.
///
/// - SeeAlso: [2.12 Directives](https://spec.graphql.org/June2018/#sec-Language.Directives)
public struct Directive {
    public var name: Name
    public var arguments: Arguments

    /// Initialize a new `Directive`.
    public init(
        name: Name,
        arguments: Arguments)
    {
        self.name = name
        self.arguments = arguments
    }
}

extension ExecutableDefinition {
    /// Initialize an `ExecutableDefinition` as an `ExecutableDefinition.operation` with the provided content.
    public init(_ op: Operation) {
        self = .operation(op)
    }

    /// Initialize an `ExecutableDefinition` as a `ExecutableDefinition.fragmentDefinition`
    /// with the provided content.
    public init(_ fragmentDefinition: FragmentDefinition) {
        self = .fragmentDefinition(fragmentDefinition)
    }

    /// Constructs an `ExecutableDefinition.operation` wrapping an `Operation.query`.
    public static func query(_ name: String, _ selections: [Selection]) -> ExecutableDefinition {
        return self.init(Operation(type: .query, name: Name(value: name), selections: selections))
    }

    /// Constructs an `ExecutableDefinition.operation` wrapping an `Operation.query`.
    public static func query(_ selections: [Selection]) -> ExecutableDefinition {
        return self.init(Operation(type: .query, selections: selections))
    }
}

extension ValidatedName: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value: value)
    }
}

extension Operation {
    /// A convenience constructor with default values for all fields that can have them.
    public init(
        type: OperationType,
        name: Name? = nil,
        variableDefinitions: [VariableDefinition] = [],
        directives: [Directive] = [],
        selections: [Selection] = [])
    {
        self.init(
            type: type,
            name: name,
            variableDefinitions: variableDefinitions,
            directives: directives,
            selectionSet: .init(selections: selections))
    }
}

extension Selection: ExpressibleByStringLiteral {
    /// A constructor that allows you to create a `Selection` with a string literal.
    public init(stringLiteral value: String) {
        self = .field(named: Name(value: value))
    }
}

extension Selection {
    public static func inlineFragment(
        on type: Name,
        directives: [Directive] = [],
        selections: [Selection] = []) -> Selection
    {
        return .inlineFragment(.init(namedType: type, directives: directives, selections: selections))
    }

    public static func field(
        named name: Name,
        arguments: Arguments = .empty,
        directives: [Directive] = [],
        selections: [Selection] = []) -> Selection
    {
        return .field(.init(name: name, arguments: arguments, directives: directives, selections: selections))
    }
}

extension SelectionSet: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Selection...) {
        self.init(selections: elements)
    }
}

extension SelectionSet {
    public init(_ selections: [Selection]) {
        self.init(selections: selections)
    }

    public init(selectionNames: [String]) {
        self.init(selections: selectionNames.map { Selection.field(.init(name: $0)) })
    }
}

extension InlineFragment {
    public init(
        namedType: Name?,
        directives: [Directive] = [],
        selections: [Selection] = [])
    {
        self.namedType = namedType
        self.directives = directives
        self.selectionSet = .init(selections)
    }
}

extension ObjectValue {
    public init(_ fields: [(Name, Any)]) {
        self.init(fields: fields)
    }
}

extension Variable {
    public init(_ name: Name) {
        self.init(name: name)
    }
}

extension Field {
    public init(
        name: Name,
        arguments: Arguments = .init(),
        directives: [Directive] = [],
        selectionSet: SelectionSet = [])
    {
        self.init(
            alias: nil,
            name: name,
            arguments: arguments,
            directives: directives,
            selectionSet: selectionSet)
    }

    public init(
        alias: Name? = nil,
        name: Name,
        arguments: Arguments = .init(),
        directives: [Directive] = [],
        selections: [Selection] = [])
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
        arguments: Arguments = .init(),
        directives: [Directive] = [],
        selections: [Selection] = [])
    {
        self.init(
            alias: alias.map(Name.init(value:)),
            name: Name(value: name),
            arguments: arguments,
            directives: directives,
            selectionSet: .init(selections: selections))
    }
}

extension Arguments: ExpressibleByDictionaryLiteral {
    public init(_ args: [(Name, Any)]) {
        self.init(args: args)
    }

    public init(dictionaryLiteral elements: (String, Any)...) {
        self.init(elements.map { (Name(value: $0.0), $0.1) })
    }
}

extension FragmentSpread: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(name: FragmentName(value: value), directives: [])
    }
}

extension FragmentDefinition {
    public init(
        name: FragmentName,
        typeCondition: Name,
        directives: [Directive] = [],
        selections: [Selection])
    {
        self.init(
            name: name,
            typeCondition: typeCondition,
            directives: directives,
            selectionSet: .init(selections))
    }

    public init(
        name: FragmentName,
        typeCondition: Name,
        directives: [Directive] = [],
        selections: [Name])
    {
        self.init(
            name: name,
            typeCondition: typeCondition,
            directives: directives,
            selectionSet: .init(selections.map { Selection.field(Field(name: $0)) }))
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


public struct GraphQLTypeError: Error {
    public let message: String
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
