import UIKit

public protocol SequenceAnimatesConvertible {
    func asSequence() -> [AnimatesInSequence]
}

public protocol SimultaneouslyAnimatesConvertible {
    func asGroup() -> [AnimatesSimultaneously]
}

extension Array: SequenceAnimatesConvertible where Element == AnimatesInSequence {
    public func asSequence() -> [AnimatesInSequence] { flatMap { $0.asSequence() } }
}

extension Array: SimultaneouslyAnimatesConvertible where Element == AnimatesSimultaneously {
    public func asGroup() -> [AnimatesSimultaneously] { flatMap { $0.asGroup() } }
}

@resultBuilder
public struct AnimationBuilder {
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

public struct AnimationPlanner {
    
    public static func plan(
        @AnimationBuilder build: () -> [AnimatesInSequence],
        completion: ((Bool) -> Void)? = nil
    ) {
        let sequence = AnimationSequence()
        sequence.steps = build().steps()
        sequence.animate(withDelay: 0, completion: completion)
    }
    
    public static func group(
        @AnimationBuilder build: () -> [AnimatesSimultaneously],
        completion: ((Bool) -> Void)? = nil
    ) {
        plan(build: {
            Group(build)
        }, completion: completion)
    }
}

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

extension Spring: Animation where Contained: Animation {
    public var options: UIView.AnimationOptions? { animation.options }
    public var timingFunction: CAMediaTimingFunction? { animation.timingFunction }
    public var changes: () -> Void { animation.changes }
}

extension Spring: AnimatesDelayed where Contained: AnimatesDelayed {
    public var delay: TimeInterval { animation.delay }
}

extension Delayed: SpringAnimates where Contained: SpringAnimates {
    public var dampingRatio: CGFloat { animation.dampingRatio }
    public var initialVelocity: CGFloat { animation.initialVelocity }
}

fileprivate extension Animates {
    var toStep: AnimationSequence.Step? {
        var delay: TimeInterval = 0
        if let delayed = self as? AnimatesDelayed {
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
