/// Result builder through which either sequence or group animations can be created. Add `@AnimationBuilder` to a closure or method to provide your own animations.
/// The result of your builder function should be an `Array` of either ``SequenceAnimatable`` or ``GroupAnimatable``.
@resultBuilder
public struct SequenceBuilder {
    public static func buildBlock(_ components: SequenceConvertible...) -> [SequenceAnimatable] {
        components.flatMap { $0.animations() }
    }
    public static func buildArray(_ components: [SequenceConvertible]) -> [SequenceAnimatable] {
        components.flatMap { $0.animations() }
    }
    public static func buildOptional(_ component: SequenceConvertible?) -> [SequenceAnimatable] {
        component.map { $0.animations() } ?? []
    }
    public static func buildEither(first component: SequenceConvertible) -> [SequenceAnimatable] {
        component.animations()
    }
    public static func buildEither(second component: SequenceConvertible) -> [SequenceAnimatable] {
        component.animations()
    }
}

@resultBuilder
public struct GroupBuilder {
    public static func buildBlock(_ components: GroupConvertible...) -> [GroupAnimatable] {
        components.flatMap { $0.animations() }
    }
    public static func buildArray(_ components: [GroupConvertible]) -> [GroupAnimatable] {
        components.flatMap { $0.animations() }
    }
    public static func buildOptional(_ component: GroupConvertible?) -> [GroupAnimatable] {
        component.map { $0.animations() } ?? []
    }
    public static func buildEither(first component: GroupConvertible) -> [GroupAnimatable] {
        component.animations()
    }
    public static func buildEither(second component: GroupConvertible) -> [GroupAnimatable] {
        component.animations()
    }
}
