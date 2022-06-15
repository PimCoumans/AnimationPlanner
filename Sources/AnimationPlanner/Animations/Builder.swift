import UIKit

/// Result builder through which either sequence or group animations can be created. Add `@AnimationBuilder` to a closure or method to provide your own animations.
/// The result of your builder function should be an `Array` of either ``AnimatesInSequence`` or ``AnimatesSimultaneously``.
@resultBuilder
public struct AnimationBuilder { }

/// Chain multiple `UIView` animations with a clear declarative syntax, describing each step along the way.
/// Start by typing `AnimationPlanner.plan` and  provide all of your animations from the `animations` closure.
///
/// Begin planning your animation by using either of the following static methods:
/// - ``plan(animations:completion:)`` start a sequence animation where all animations are performed in order.
/// - ``group(animations:completion:)`` start a group animation where all animations are performed simultaneously.
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
    ///   - animations: Add each animation using this closure. Animation added to a sequence should conform to ``AnimatesSimultaneously``.
    ///   - completion: Called when the animation sequence has finished
    public static func plan(
        @AnimationBuilder animations builder: () -> [AnimatesInSequence],
        completion: ((Bool) -> Void)? = nil
    ) {
        let sequence = AnimationSequence()
        sequence.steps = builder().steps()
        sequence.animate(withDelay: 0, completion: completion)
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
    ///   - animations: Add each animation using this closure. Animation added to a group should conform to ``AnimatesSimultaneously``.
    ///   - completion: Called when the animation sequence has finished
    public static func group(
        @AnimationBuilder animations builder: () -> [AnimatesSimultaneously],
        completion: ((Bool) -> Void)? = nil
    ) {
        plan(animations: {
            Group(animations: builder)
        }, completion: completion)
    }
}

// MARK: - Building sequences

/// Provides a way to create a uniform sequence from all animations conforming to ``AnimatesInSequence``
public protocol SequenceAnimatesConvertible {
    func asSequence() -> [AnimatesInSequence]
}

/// Provides a way to group toghether animations conforming to ``AnimatesSimultaneously``
public protocol SimultaneouslyAnimatesConvertible {
    func asGroup() -> [AnimatesSimultaneously]
}

extension Array: SequenceAnimatesConvertible where Element == AnimatesInSequence {
    public func asSequence() -> [AnimatesInSequence] { flatMap { $0.asSequence() } }
}

extension Array: SimultaneouslyAnimatesConvertible where Element == AnimatesSimultaneously {
    public func asGroup() -> [AnimatesSimultaneously] { flatMap { $0.asGroup() } }
}

extension AnimationBuilder {
    public static func buildBlock(_ components: SequenceAnimatesConvertible...) -> [AnimatesInSequence] {
        components.flatMap { $0.asSequence() }
    }
    
    public static func buildArray(_ components: [SequenceAnimatesConvertible]) -> [AnimatesInSequence] {
        components.flatMap { $0.asSequence() }
    }
    
    public static func buildOptional(_ component: SequenceAnimatesConvertible?) -> [AnimatesInSequence] {
        component.map { $0.asSequence() } ?? []
    }
    public static func buildEither(first component: SequenceAnimatesConvertible) -> [AnimatesInSequence] {
        component.asSequence()
    }
    public static func buildEither(second component: SequenceAnimatesConvertible) -> [AnimatesInSequence] {
        component.asSequence()
    }
}

extension AnimationBuilder {
    public static func buildBlock(_ components: SimultaneouslyAnimatesConvertible...) -> [AnimatesSimultaneously] {
        components.flatMap { $0.asGroup() }
    }
    
    public static func buildArray(_ components: [SimultaneouslyAnimatesConvertible]) -> [AnimatesSimultaneously] {
        components.flatMap { $0.asGroup() }
    }
    
    public static func buildOptional(_ component: SimultaneouslyAnimatesConvertible?) -> [AnimatesSimultaneously] {
        component.map { $0.asGroup() } ?? []
    }
    public static func buildEither(first component: SimultaneouslyAnimatesConvertible) -> [AnimatesSimultaneously] {
        component.asGroup()
    }
    public static func buildEither(second component: SimultaneouslyAnimatesConvertible) -> [AnimatesSimultaneously] {
        component.asGroup()
    }
}

// MARK: - Converting to ``AnimationSequence.Step``

fileprivate extension Array where Element == AnimatesInSequence {
    func steps() -> [AnimationSequence.Step] {
        compactMap(\.toStep)
    }
}

fileprivate extension Array where Element == AnimatesSimultaneously {
    func steps() -> [AnimationSequence.Step] {
        compactMap(\.toStep)
    }
}

fileprivate extension Animates {
    var toStep: AnimationSequence.Step? {
        var delay: TimeInterval = 0
        if let delayed = self as? DelayedAnimates {
            // Grab delay if animation has a delay
            delay = delayed.delay
        }
        switch self {
        case let spring as SpringAnimates & Animation:
            return .springAnimation(
                duration: spring.duration,
                delay: delay,
                dampingRatio: spring.dampingRatio,
                velocity: spring.initialVelocity,
                options: spring.options,
                animations: spring.changes)
        case let extra as AnimatesExtra:
            return .extra(delay: delay, handler: extra.perform)
        case let animation as Animation:
            return .animation(
                duration: animation.duration,
                delay: delay,
                options: animation.options,
                timingFunction: animation.timingFunction,
                animations: animation.changes
            )
        case let delay as Wait:
            return .delay(duration: delay.duration)
        case let group as Group:
            return .group(animations: group.animations.steps())
        case let sequence as Sequence:
            return .sequence(sequence: AnimationSequence(steps: sequence.animations.steps()))
        default:
            return nil
        }
    }
}

fileprivate extension AnimationSequence {
    convenience init(steps: [Step]) {
        self.init()
        self.steps = steps
    }
}
