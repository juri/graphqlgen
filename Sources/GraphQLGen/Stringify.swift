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
    static let compact = Stringifier(stringify: compactFragmentSpreadStringify)
}

public extension Stringifier where A == GraphQL.FragmentDefinition {
    static let compact = Stringifier(stringify: compactFragmentDefStringify)
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

public extension Stringifier where A == GraphQL.ObjectValue {
    static let compact = Stringifier(stringify: compactObjectValueStringify)
}

public extension Stringifier where A == GraphQL.Variable {
    static let normal = Stringifier(stringify: normalVariableStringify)
}

public extension Stringifier where A == GraphQL.TypeReference {
    static let compact = Stringifier(stringify: compactTypeReferenceStringify(typeRef:))
}

public extension Stringifier where A == GraphQL.VariableDefinition {
    static let compact = Stringifier(stringify: compactVariableDefinitionStringify(vdef:))
}

// MARK: -

func normalStringStringify(_ s: String) -> String {
    return #""\#(GraphQL.escape(s))""#
}

func normalIntStringify(_ i: Int) -> String {
    return "\(i)"
}

func normalFloatStringify(_ f: Float) -> String {
    return "\(f)"
}

func normalDoubleStringify(_ d: Double) -> String {
    return "\(d)"
}

func normalBoolStringify(_ b: Bool) -> String {
    return "\(b)"
}

func compactDictStringify(_ d: [String: Any]) throws -> String {
    let encodedPairs = try d.map(GraphQL.encodePair(key:value:))
    return #"{\#(encodedPairs.joined(separator: " "))}"#
}

func compactArrayStringify(_ a: [Any]) throws -> String {
    let encodedValues = try a.map(stringifyArgument(value:))
    return #"[\#(encodedValues.joined(separator: " "))]"#
}

func compactGraphQLStringify(gql: GraphQL) throws -> String {
    switch gql {
    case let .operation(op):
        return try Stringifier.compact.stringify(op)
    case let .inlineFragment(inlineFragment):
        return try Stringifier.compact.stringify(inlineFragment)
    case let .fragmentSpread(fs):
        return try Stringifier.compact.stringify(fs)
    case let .field(field):
        return try Stringifier.compact.stringify(field)
    case let .fragmentDefinition(fdef):
        return try Stringifier.compact.stringify(fdef)
    }
}

func normalNameStringify(_ n: GraphQL.Name) throws -> String {
    guard validateName(n.value) else { throw GraphQL.Name.BadValue(value: n.value) }
    return n.value
}

func compactArgsStringify(a: GraphQL.Arguments) throws -> String {
    guard !a.args.isEmpty else { return "" }
    let args = try a.args.map(stringifyArgument(name:value:))
    return #"(\#(args.joined(separator: " ")))"#
}

func compactFieldStringify(field: GraphQL.Field) throws -> String {
    let args = try Stringifier.compact.stringify(field.arguments)
    let name = try Stringifier.normal.stringify(field.name)
    let aliasPrefix = try field.alias.map { (try Stringifier.normal.stringify($0) + ": ") } ?? ""
    let selections = field.selectionSet.selections.isEmpty
        ? ""
        : " " + (try Stringifier.compact.stringify(field.selectionSet))
    return #"\#(aliasPrefix)\#(name)\#(args)\#(selections)"#
}

func normalFragmentNameStringify(_ n: GraphQL.FragmentName) throws -> String {
    guard validateFragmentName(n.value) else { throw GraphQL.FragmentName.BadValue(value: n.value) }
    return n.value
}

func compactFragmentSpreadStringify(frag: GraphQL.FragmentSpread) throws -> String {
    let name = try Stringifier.normal.stringify(frag.name)
    return "... \(name)"
}

func compactFragmentDefStringify(frag: GraphQL.FragmentDefinition) throws -> String {
    let name = try Stringifier.normal.stringify(frag.name)
    let typeCondition = try Stringifier.normal.stringify(frag.typeCondition)
    let selectionSet = try Stringifier.compact.stringify(frag.selectionSet)
    return "fragment \(name) on \(typeCondition) \(selectionSet)"
}

func compactOpStringify(op: GraphQL.Operation) throws -> String {
    let name = try op.name.map(Stringifier.normal.stringify)
    let vdefs = op.variableDefinitions.isEmpty
        ? nil
        : "(" + (try op.variableDefinitions.map(Stringifier.compact.stringify).joined(separator: " ")) + ")"
    let selections = try Stringifier.compact.stringify(op.selectionSet)
    return [op.type.rawValue, name, vdefs, selections]
        .compactMap { $0 }
        .joined(separator: " ")
}

func compactInlineFragmentStringify(frag: GraphQL.InlineFragment) throws -> String {
    let cstr = try Stringifier.compact.stringify(frag.selectionSet)
    let typeCondition = frag.namedType.isEmpty ? "" : "... on \(frag.namedType) "
    return "\(typeCondition)\(cstr)"
}

func compactSelectionStringify(sel: GraphQL.Selection) throws -> String {
    switch sel {
    case let .field(field):
        return try Stringifier.compact.stringify(field)
    case let .fragmentSpread(fragmentSpread):
        return try Stringifier.compact.stringify(fragmentSpread)
    case let .inlineFragment(inlineFragment):
        return try Stringifier.compact.stringify(inlineFragment)
    }
}

func compactSelSetStringify(selSet: GraphQL.SelectionSet) throws -> String {
    let selections: [GraphQL.Selection] = selSet.selections
    let stringifiedSelections: [String] = try selections.map { (s: GraphQL.Selection) throws -> String in try Stringifier.compact.stringify(s) }
    let joined: String = stringifiedSelections.joined(separator: " ")
    return #"{ \#(joined) }"#
}

func compactObjectValueStringify(objectValue: GraphQL.ObjectValue) throws -> String {
    guard !objectValue.fields.isEmpty else { return "{}" }
    let fields = try objectValue.fields.map(stringifyArgument(name:value:))
    return #"{\#(fields.joined(separator: " "))}"#
}

func normalVariableStringify(variable: GraphQL.Variable) throws -> String {
    let varName = try Stringifier.normal.stringify(variable.name)
    return "$\(varName)"
}

func compactTypeReferenceStringify(typeRef: GraphQL.TypeReference) throws -> String {
    let strn = { (n: GraphQL.Name) in try Stringifier.normal.stringify(n) }
    let strl = { (l: [GraphQL.TypeReference]) in
        "[" + (try l.map(compactTypeReferenceStringify(typeRef:)).joined(separator: " ")) + "]"
    }

    switch typeRef {
    case let .named(n): return try strn(n)
    case let .list(l): return try strl(l)
    case let .nonNull(nn):
        switch nn {
        case let .named(n): return try strn(n) + "!"
        case let .list(l): return try strl(l) + "!"
        }
    }
}

func compactVariableDefinitionStringify(vdef: GraphQL.VariableDefinition) throws -> String {
    let name = try Stringifier.normal.stringify(vdef.variable)
    let type = try Stringifier.compact.stringify(vdef.type)
    return "\(name): \(type)"
}
