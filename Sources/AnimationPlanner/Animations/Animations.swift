import UIKit

/// Performs an animation with for the provided duration in seconds, with an
public struct Animate: Animation, AnimatesInSequence, AnimatesSimultaneously {
    public let duration: TimeInterval
    public var totalDuration: TimeInterval { duration }
    
    public internal(set) var changes: () -> Void
    public internal(set) var options: UIView.AnimationOptions?
    public internal(set) var timingFunction: CAMediaTimingFunction?
    
    public init(duration: TimeInterval, changes: @escaping () -> Void = {}) {
        self.duration = duration
        self.changes = changes
    }
}

/// Pauses the sequences for the given amount of seconds
public struct Wait: AnimatesInSequence {
    public let duration: TimeInterval
    
    public init(_ duration: TimeInterval) {
        self.duration = duration
    }
}

/// Perfoms the provided handler in between your actual animations.
/// Typically used for setting up state before an animation or creating side-effects like haptic feedback.
public struct Extra: AnimatesExtra, AnimatesInSequence, AnimatesSimultaneously {
    public let duration: TimeInterval = 0
    
    public var perform: () -> Void
    public init(perform: @escaping () -> Void) {
        self.perform = perform
    }
}

/// Adds custom behaviour on top of the contained animation. Forwards all required `Animation` properties to the contained animation
public protocol AnimationContainer {
    associatedtype Contained: Animates
    var animation: Contained { get }
}

extension AnimationContainer where Contained: Animation {
    public var duration: TimeInterval { animation.duration }
    public var changes: () -> Void { animation.changes }
    public var options: UIView.AnimationOptions? { animation.options }
    public var timingFunction: CAMediaTimingFunction? { animation.timingFunction }
}

/// Performs an animation with spring dampening applied, using the same values as UIView spring animations
public struct AnimateSpring<T: Animation>: SpringAnimates, AnimationContainer, AnimatesSimultaneously {
    public internal(set) var animation: T
    public var totalDuration: TimeInterval { duration }
    
    public let dampingRatio: CGFloat
    public let initialVelocity: CGFloat
    
    internal init(dampingRatio: CGFloat, initialVelocity: CGFloat, animation: T) {
        self.animation = animation
        self.dampingRatio = dampingRatio
        self.initialVelocity = initialVelocity
    }
}

extension AnimateSpring where T == Animate {
    public init(
        duration: TimeInterval,
        dampingRatio: CGFloat,
        initialVelocity: CGFloat = 0,
        changes: @escaping () -> Void = {}
    ) {
        let animation = Animate(duration: duration, changes: changes)
        self.init(dampingRatio: dampingRatio, initialVelocity: initialVelocity, animation: animation)
    }
}

extension AnimateSpring: AnimatesInSequence, AnimatesInSequenceConvertible where Contained: AnimatesInSequence {
    public func asSequence() -> [AnimatesInSequence] {
        [self]
    }
}

/// Performs an animation after a delay, only to be used in a context where other animations are run simultaneously
public struct AnimateDelayed<T: Animates>: AnimationContainer, DelayedAnimates, AnimatesSimultaneously {
    
    public internal(set) var animation: T
    public var duration: TimeInterval { animation.duration }
    public var totalDuration: TimeInterval { delay + animation.duration }
    
    public let delay: TimeInterval
    
    internal init(delay: TimeInterval, animation: T) {
        self.animation = animation
        self.delay = delay
    }
}

extension AnimateDelayed where T == Animate {
    public init(
        delay: TimeInterval,
        duration: TimeInterval,
        changes: @escaping () -> Void = {}
    ) {
        let animation = Animate(duration: duration, changes: changes)
        self.init(delay: delay, animation: animation)
    }
}
