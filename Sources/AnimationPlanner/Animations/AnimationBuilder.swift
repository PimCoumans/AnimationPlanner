/// Result builder through which either sequence or group animations can be created. Add `@AnimationBuilder` to a closure or method to provide your own animations.
/// The result of your builder function should be an `Array` of either ``SequenceAnimatable`` or ``GroupAnimatable``.
@resultBuilder
public struct AnimationBuilder { }

extension AnimationBuilder {
    public static func buildBlock(_ components: SequenceConvertible...) -> [SequenceAnimatable] {
        components.flatMap { $0.asSequence() }
    }
    
    public static func buildArray(_ components: [SequenceConvertible]) -> [SequenceAnimatable] {
        components.flatMap { $0.asSequence() }
    }
    
    public static func buildOptional(_ component: SequenceConvertible?) -> [SequenceAnimatable] {
        component.map { $0.asSequence() } ?? []
    }
    public static func buildEither(first component: SequenceConvertible) -> [SequenceAnimatable] {
        component.asSequence()
    }
    public static func buildEither(second component: SequenceConvertible) -> [SequenceAnimatable] {
        component.asSequence()
    }
}

extension AnimationBuilder {
    public static func buildBlock(_ components: GroupConvertible...) -> [GroupAnimatable] {
        components.flatMap { $0.asGroup() }
    }
    
    public static func buildArray(_ components: [GroupConvertible]) -> [GroupAnimatable] {
        components.flatMap { $0.asGroup() }
    }
    
    public static func buildOptional(_ component: GroupConvertible?) -> [GroupAnimatable] {
        component.map { $0.asGroup() } ?? []
    }
    public static func buildEither(first component: GroupConvertible) -> [GroupAnimatable] {
        component.asGroup()
    }
    public static func buildEither(second component: GroupConvertible) -> [GroupAnimatable] {
        component.asGroup()
    }
}
