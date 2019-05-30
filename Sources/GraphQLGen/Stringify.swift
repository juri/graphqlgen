/// `Stringifier` is a protocol witness for stringifying a `GraphQL`.
/// There are implementations for the various structures as static properties
/// in the appropriately typed extensions.
public struct Stringifier<A> {
    public var stringify: (A) throws -> String
}

public extension Stringifier where A == String {
    static let normal = Stringifier(stringify: InputValueFormat.formatString(_:))
}

public extension Stringifier where A == ExecutableDefinition {
    static let compact = Stringifier(stringify: compactExecutableDefinitionStringify)
}

public extension Stringifier where A == Name {
    static let normal = Stringifier(stringify: normalNameStringify)
}

public extension Stringifier where A == Arguments {
    static let compact = Stringifier(stringify: compactArgsStringify)
}

public extension Stringifier where A == Field {
    static let compact = Stringifier(stringify: compactFieldStringify)
}

public extension Stringifier where A == FragmentName {
    static let normal = Stringifier(stringify: normalFragmentNameStringify)
}

public extension Stringifier where A == FragmentSpread {
    static let compact = Stringifier(stringify: compactFragmentSpreadStringify)
}

public extension Stringifier where A == FragmentDefinition {
    static let compact = Stringifier(stringify: compactFragmentDefStringify)
}

public extension Stringifier where A == InlineFragment {
    static let compact = Stringifier(stringify: compactInlineFragmentStringify)
}

public extension Stringifier where A == Operation {
    static let compact = Stringifier(stringify: compactOpStringify)
}

public extension Stringifier where A == Selection {
    static let compact = Stringifier(stringify: compactSelectionStringify)
}

public extension Stringifier where A == SelectionSet {
    static let compact = Stringifier(stringify: compactSelSetStringify)
}

public extension Stringifier where A == ObjectValue {
    static let compact = Stringifier(stringify: compactObjectValueStringify)
}

public extension Stringifier where A == Variable {
    static let normal = Stringifier(stringify: normalVariableStringify)
}

public extension Stringifier where A == TypeReference {
    static let compact = Stringifier(stringify: compactTypeReferenceStringify(typeRef:))
}

public extension Stringifier where A == VariableDefinition {
    static let compact = Stringifier(stringify: compactVariableDefinitionStringify(vdef:))
}

public extension Stringifier where A == Directive {
    static let compact = Stringifier(stringify: compactDirectiveStringify(directive:))
}

// MARK: -

public enum InputValueFormat {
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

    public static func formatString(_ s: String) -> String {
        return #""\#(escape(s))""#
    }

    public static func formatInt(_ i: Int) -> String {
        return "\(i)"
    }

    public static func formatFloat(_ f: Float) -> String {
        return "\(f)"
    }

    public static func formatDouble(_ d: Double) -> String {
        return "\(d)"
    }

    public static func formatBool(_ b: Bool) -> String {
        return "\(b)"
    }

    public static func encodePair(key: String, value: Any) throws -> String {
        let encodedValue = try compactFormat(value: value)
        return "\(key): \(encodedValue)"
    }
}

func compactFormat(value: Any) throws -> String {
    switch value {
    case let s as String:
        return InputValueFormat.formatString(s)
    case let i as Int:
        return InputValueFormat.formatInt(i)
    case let f as Float:
        return InputValueFormat.formatFloat(f)
    case let d as Double:
        return InputValueFormat.formatDouble(d)
    case let b as Bool:
        return InputValueFormat.formatBool(b)
    case let dict as [String: Any]:
        return try compactDictStringify(dict)
    case let arr as [Any]:
        return try compactArrayStringify(arr)
    case let v as Variable:
        return try normalVariableStringify(variable: v)
    case let o as ObjectValue:
        return try compactObjectValueStringify(objectValue: o)
    default:
        throw GraphQLTypeError(message: "Unsupported type of \(value): \(type(of: value))")
    }
}

func compactFormat(name: Name, value: Any) throws -> String {
    let vstr = try compactFormat(value: value)
    let nstr = try normalNameStringify(name)
    return "\(nstr): \(vstr)"
}

func compactDictStringify(_ d: [String: Any]) throws -> String {
    let encodedPairs = try d.map(InputValueFormat.encodePair(key:value:))
    return #"{\#(encodedPairs.joined(separator: " "))}"#
}

func compactArrayStringify(_ a: [Any]) throws -> String {
    let encodedValues = try a.map(compactFormat(value:))
    return #"[\#(encodedValues.joined(separator: " "))]"#
}

func compactExecutableDefinitionStringify(gql: ExecutableDefinition) throws -> String {
    switch gql {
    case let .operation(op):
        return try Stringifier.compact.stringify(op)
    case let .fragmentDefinition(fdef):
        return try Stringifier.compact.stringify(fdef)
    }
}

func normalNameStringify(_ n: Name) throws -> String {
    guard validateName(n.value) else { throw Name.BadValue(value: n.value) }
    return n.value
}

func compactArgsStringify(a: Arguments) throws -> String {
    guard !a.args.isEmpty else { return "" }
    let args = try a.args.map(compactFormat(name:value:))
    return #"(\#(args.joined(separator: " ")))"#
}

func compactFieldStringify(field: Field) throws -> String {
    let args = try Stringifier.compact.stringify(field.arguments)
    let name = try Stringifier.normal.stringify(field.name)
    let aliasPrefix = try field.alias.map { (try Stringifier.normal.stringify($0) + ": ") } ?? ""
    let directives = field.directives.isEmpty
        ? ""
        : " " + (try field.directives.map(Stringifier.compact.stringify).joined(separator: " "))
    let selections = field.selectionSet.selections.isEmpty
        ? ""
        : " " + (try Stringifier.compact.stringify(field.selectionSet))
    return #"\#(aliasPrefix)\#(name)\#(args)\#(directives)\#(selections)"#
}

func normalFragmentNameStringify(_ n: FragmentName) throws -> String {
    guard validateFragmentName(n.value) else { throw FragmentName.BadValue(value: n.value) }
    return n.value
}

func compactFragmentSpreadStringify(frag: FragmentSpread) throws -> String {
    let name = try Stringifier.normal.stringify(frag.name)
    let directives = frag.directives.isEmpty
        ? ""
        : " " + (try frag.directives.map(Stringifier.compact.stringify).joined(separator: " "))
    return "... \(name)\(directives)"
}

func compactFragmentDefStringify(frag: FragmentDefinition) throws -> String {
    let name = try Stringifier.normal.stringify(frag.name)
    let typeCondition = try Stringifier.normal.stringify(frag.typeCondition)
    let directives = frag.directives.isEmpty
        ? ""
        : " " + (try frag.directives.map(Stringifier.compact.stringify).joined(separator: " "))
    let selectionSet = try Stringifier.compact.stringify(frag.selectionSet)
    return "fragment \(name) on \(typeCondition)\(directives) \(selectionSet)"
}

func compactOpStringify(op: Operation) throws -> String {
    let name = try op.name.map(Stringifier.normal.stringify)
    let vdefs = op.variableDefinitions.isEmpty
        ? nil
        : "(" + (try op.variableDefinitions.map(Stringifier.compact.stringify).joined(separator: " ")) + ")"
    let directives = op.directives.isEmpty
        ? nil
        : try op.directives.map(Stringifier.compact.stringify).joined(separator: " ")
    let selections = try Stringifier.compact.stringify(op.selectionSet)
    return [op.type.rawValue, name, vdefs, directives, selections]
        .compactMap { $0 }
        .joined(separator: " ")
}

func compactInlineFragmentStringify(frag: InlineFragment) throws -> String {
    let cstr = try Stringifier.compact.stringify(frag.selectionSet)
    let typeCondition = frag.namedType.isEmpty ? "" : "... on \(frag.namedType) "
    return "\(typeCondition)\(cstr)"
}

func compactSelectionStringify(sel: Selection) throws -> String {
    switch sel {
    case let .field(field):
        return try Stringifier.compact.stringify(field)
    case let .fragmentSpread(fragmentSpread):
        return try Stringifier.compact.stringify(fragmentSpread)
    case let .inlineFragment(inlineFragment):
        return try Stringifier.compact.stringify(inlineFragment)
    }
}

func compactSelSetStringify(selSet: SelectionSet) throws -> String {
    let selections: [Selection] = selSet.selections
    let stringifiedSelections: [String] = try selections.map { (s: Selection) throws -> String in try Stringifier.compact.stringify(s) }
    let joined: String = stringifiedSelections.joined(separator: " ")
    return #"{ \#(joined) }"#
}

func compactObjectValueStringify(objectValue: ObjectValue) throws -> String {
    guard !objectValue.fields.isEmpty else { return "{}" }
    let fields = try objectValue.fields.map(compactFormat(name:value:))
    return #"{\#(fields.joined(separator: " "))}"#
}

func normalVariableStringify(variable: Variable) throws -> String {
    let varName = try Stringifier.normal.stringify(variable.name)
    return "$\(varName)"
}

func compactTypeReferenceStringify(typeRef: TypeReference) throws -> String {
    let strn = { (n: Name) in try Stringifier.normal.stringify(n) }
    let strl = { (l: [TypeReference]) in
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

func compactVariableDefinitionStringify(vdef: VariableDefinition) throws -> String {
    let name = try Stringifier.normal.stringify(vdef.variable)
    let type = try Stringifier.compact.stringify(vdef.type)
    return "\(name): \(type)"
}

func compactDirectiveStringify(directive: Directive) throws -> String {
    let name = try Stringifier.normal.stringify(directive.name)
    let args = try Stringifier.compact.stringify(directive.arguments)
    return "@\(name)\(args)"
}

/// Helper extensions

extension ExecutableDefinition {
    /// Retuns a compact string representation using `Stringifier.compact(_:)`.
    public func compactString() throws -> String {
        return try Stringifier.compact.stringify(self)
    }
}

extension Field {
    /// Retuns a compact string representation using `Stringifier.compact(_:)`.
    public func compactString() throws -> String {
        return try Stringifier.compact.stringify(self)
    }
}

extension FragmentSpread {
    /// Retuns a compact string representation using `Stringifier.compact(_:)`.
    public func compactString() throws -> String {
        return try Stringifier.compact.stringify(self)
    }
}
