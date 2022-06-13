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

fileprivate extension Animates {
    var toStep: AnimationSequence.Step? {
        switch self {
        case let container as AnimationContainer:
            return container.parseContainer()
        case let animation as Animation:
            return .animation(
                duration: animation.duration,
                delay: 0,
                options: animation.options,
                timingFunction: animation.timingFunction,
                animations: animation.changes
            )
        case let delay as Wait:
            return .delay(duration: delay.duration)
        case let extra as Extra:
            return .extra(delay: 0, handler: extra.perform)
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

fileprivate extension AnimationContainer {
    /// Animations conforming to ``AnimationContainer`` can themselves contain a container,
    /// so when a ``AnimateDelayed`` animation contains a ``AnimateSpring``, the values
    /// of the spring should not get lost. So we recursively parse each contained animation so no
    /// values get skipped
    func parseContainer() -> AnimationSequence.Step {
        
        var containedAnimations = [Animation]()
        
        var animation: Animation? = self
        while let foundAnimation = animation {
            containedAnimations.append(foundAnimation)
            animation = (foundAnimation as? AnimationContainer)?.animation
        }
        
        let springAnimation: AnimateSpring? = containedAnimations
            .lazy
            .compactMap { $0 as? AnimateSpring }
            .first
        
        let totalDelay: TimeInterval = containedAnimations
            .compactMap { $0 as? AnimatesDelayed }
            .reduce(0, { $0 + $1.delay })
        
        if let springAnimation = springAnimation {
            return .springAnimation(
                duration: duration,
                delay: totalDelay,
                dampingRatio: springAnimation.dampingRatio,
                velocity: springAnimation.initialVelocity,
                options: options ?? [],
                animations: changes)
        }
        return .animation(
            duration: duration,
            delay: totalDelay,
            options: options,
            timingFunction: timingFunction,
            animations: changes)
    }
}
