import UIKit

/// Result builder through which either sequence or group animations can be created. Add `@AnimationBuilder` to a closure or method to provide your own animations.
/// The result of your builder function should be an `Array` of either ``SequenceAnimatable`` or ``GroupAnimatable``.
@resultBuilder
public struct AnimationBuilder { }

/// Chain multiple `UIView` animations with a clear declarative syntax, describing each step along the way.
/// Start by typing `AnimationPlanner.plan` and  provide all of your animations from the `animations` closure.
///
/// Begin planning your animation by using either of the following static methods:
/// - ``plan(animations:)`` start a sequence animation where all animations are performed in order.
/// - ``group(animations:)`` start a group animation where all animations are performed simultaneously.
///
/// - Tip:  To get started,  read <doc:creating-basic-animation-sequence> and get up to speed on how to use AnimationPlanner,
/// or go through the whole documentation on ``AnimationPlanner`` to get an overview of all the available functionalities.
public struct AnimationPlanner {
    
    /// Start a new animation sequence where animations added will be performed in order, meaning a subsequent animation starts right after the previous finishes.
    ///
    /// ```swift
    /// AnimationPlanner.plan {
    ///     Animate(duration: 0.25) { view.backgroundColor = .systemRed }
    ///     Wait(0.5)
    ///     Animate(duration: 0.5) {
    ///         view.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
    ///     }.spring(damping: 0.68)
    /// }
    /// ```
    /// - Parameters:
    ///   - animations: Add each animation using this closure. Animation added to a sequence should conform to ``GroupAnimatable``.
    /// - Returns: Instance of ``RunningSequence`` to keep track of and stop animations
    @discardableResult
    public static func plan(
        @AnimationBuilder animations builder: () -> [SequenceAnimatable]
    ) -> RunningSequence {
        let running = RunningSequence(animations: builder())
        running.animate()
        return running
    }
    
    /// Start a new group animation where animations added will be performed simultaneously, meaning all animations run at the same time.
    ///
    /// ```swift
    /// AnimationPlanner.group {
    ///     Animate(duration: 0.5) {
    ///         view.frame.origin.y = 0
    ///     }.delayed(0.15)
    ///     Animate(duration: 0.3) {
    ///         view.backgroundColor = .systemBlue
    ///     }.delayed(0.2)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - animations: Add each animation using this closure. Animation added to a group should conform to ``GroupAnimatable``.
    /// - Returns: Instance of ``RunningSequence`` to keep track of and stop animations
    @discardableResult
    public static func group(
        @AnimationBuilder animations builder: () -> [GroupAnimatable]
    ) -> RunningSequence {
        plan {
            Group(animations: builder)
        }
    }
}

// MARK: - Building sequences

/// Provides a way to create a uniform sequence from all animations conforming to ``SequenceAnimatable``
public protocol SequenceConvertible {
    func asSequence() -> [SequenceAnimatable]
}

/// Provides a way to group toghether animations conforming to ``GroupAnimatable``
public protocol GroupConvertible {
    func asGroup() -> [GroupAnimatable]
}

extension Array: SequenceConvertible where Element == SequenceAnimatable {
    public func asSequence() -> [SequenceAnimatable] { flatMap { $0.asSequence() } }
}

extension Array: GroupConvertible where Element == GroupAnimatable {
    public func asGroup() -> [GroupAnimatable] { flatMap { $0.asGroup() } }
}

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
