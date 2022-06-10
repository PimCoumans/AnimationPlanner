import UIKit

public protocol SequenceAnimationConvertible {
    func asSequence() -> [SequenceAnimates]
}

public protocol GroupAnimationConvertible {
    func asGroup() -> [GroupAnimates]
}

extension Array: SequenceAnimationConvertible where Element == SequenceAnimates {
    public func asSequence() -> [SequenceAnimates] { flatMap { $0.asSequence() } }
}

extension Array: GroupAnimationConvertible where Element == GroupAnimates {
    public func asGroup() -> [GroupAnimates] { flatMap { $0.asGroup() } }
}

@resultBuilder
public struct AnimationBuilder<Animation> { }

extension AnimationBuilder where Animation == SequenceAnimates {
    public static func buildBlock(_ components: SequenceAnimationConvertible...) -> [SequenceAnimates] {
        components.flatMap { $0.asSequence() }
    }
}

extension AnimationBuilder where Animation == GroupAnimates {
    
    public static func buildBlock(_ components: GroupAnimationConvertible...) -> [GroupAnimates] {
        components.flatMap { $0.asGroup() }
    }
}

public struct AnimationPlanner {
    
    public static func plan(
        @AnimationBuilder<SequenceAnimates> build: () -> [SequenceAnimates],
        completion: ((Bool) -> Void)? = nil
    ) {
        let sequence = AnimationSequence()
        sequence.steps = build().steps()
        sequence.animate(withDelay: 0, completion: completion)
    }
    
    public static func group(
        @AnimationBuilder<GroupAnimates> build: () -> [GroupAnimates],
        completion: ((Bool) -> Void)? = nil
    ) {
        plan(build: {
            Group(build)
        }, completion: completion)
    }
}

fileprivate extension Array where Element == SequenceAnimates {
    func steps() -> [AnimationSequence.Step] {
        compactMap(\.toStep)
    }
}

fileprivate extension Array where Element == GroupAnimates {
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
        default:
            return nil
        }
    }
}

fileprivate extension AnimationContainer {
    func parseContainer() -> AnimationSequence.Step {
        var springAnimation: AnimateSpring?
        var delay: TimeInterval = 0
        var options: UIView.AnimationOptions = []
        var timingFunction: CAMediaTimingFunction?
        
        var containedAnimations = [Animation]()
        
        var animation: Animation? = self
        while let foundAnimation = animation {
            containedAnimations.append(foundAnimation)
            animation = (foundAnimation as? AnimationContainer)?.animation
        }
        
        // Move from first added animation to the last
        containedAnimations.reversed().forEach { animation in
            options = animation.options.map { options.union($0) } ?? options
            timingFunction = animation.timingFunction ?? timingFunction
            springAnimation = animation as? AnimateSpring ?? springAnimation
            delay += (animation as? AnimateDelayed)?.delay ?? 0
        }
        
        if let springAnimation = springAnimation {
            return .springAnimation(
                duration: duration,
                delay: delay,
                dampingRatio: springAnimation.dampingRatio,
                velocity: springAnimation.initialVelocity,
                options: options,
                animations: changes)
        }
        return .animation(
            duration: duration,
            delay: delay,
            options: options,
            timingFunction: timingFunction,
            animations: changes)
    }
}
