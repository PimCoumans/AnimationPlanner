import UIKit

/// Performs an animation with for the provided duration in seconds, with an
public struct Animate: Animation, AnimatesInSequence, AnimatesSimultaneously {
    public let duration: TimeInterval
    public var totalDuration: TimeInterval { duration }
    
    public internal(set) var changes: () -> Void
    public internal(set) var options: UIView.AnimationOptions?
    public internal(set) var timingFunction: CAMediaTimingFunction?
    
    /// Creates a new animation, animating the properties updated in the ``changes`` closure
    ///
    /// - Note: AnimationPlanner includes numerous animation curves through a `CAMediaTimingFunction` extension.
    /// Type a period for the `timingFunction` parameter to see what is readily available. Have you tried `.quintOut` yet?
    /// - Parameters:
    ///   - duration: Duration of animation, measured in seconds
    ///   - timingFunction: Optional `CAMediaTimingFunction` to interpolate animated values with.
    ///   - changes: Closure executed when the animation is performed
    public init(
        duration: TimeInterval,
        timingFunction: CAMediaTimingFunction? = nil,
        changes: @escaping () -> Void = {}
    ) {
        self.duration = duration
        self.timingFunction = timingFunction
        self.changes = changes
    }
}

/// Pauses the sequence for the given amount of seconds before performing the next animation.
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

// MARK: - Container

/// Adds custom behaviour on top of the contained animation. Forwards all required `Animation` properties to the contained animation
public protocol AnimationContainer {
    associatedtype Contained: Animates
    var animation: Contained { get }
}

/// Forwarding ``Animation`` properties
extension AnimationContainer where Contained: Animation {
    public var duration: TimeInterval { animation.duration }
    public var changes: () -> Void { animation.changes }
    public var options: UIView.AnimationOptions? { animation.options }
    public var timingFunction: CAMediaTimingFunction? { animation.timingFunction }
}

/// Forwarding ``DelayedAnimates`` properties
extension AnimationContainer where Contained: DelayedAnimates {
    public var delay: TimeInterval { animation.delay }
}

/// Forwarding ``SpringAnimates`` properties
extension AnimationContainer where Contained: SpringAnimates {
    public var dampingRatio: CGFloat { animation.dampingRatio }
    public var initialVelocity: CGFloat { animation.initialVelocity }
}

// MARK: - Spring

/// Performs an animation with spring dampening applied, using the same values as UIView spring animations
public struct AnimateSpring<Springed: Animation>: SpringAnimates, AnimationContainer, AnimatesSimultaneously {
    public internal(set) var animation: Springed
    public var totalDuration: TimeInterval { duration }
    
    public let dampingRatio: CGFloat
    public let initialVelocity: CGFloat
    
    internal init(dampingRatio: CGFloat, initialVelocity: CGFloat, animation: Springed) {
        self.animation = animation
        self.dampingRatio = dampingRatio
        self.initialVelocity = initialVelocity
    }
}

extension AnimateSpring where Springed == Animate {
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

extension AnimateSpring: AnimatesInSequence, SequenceAnimatesConvertible where Contained: AnimatesInSequence {
    public func asSequence() -> [AnimatesInSequence] {
        [self]
    }
}

extension AnimateSpring: Animation where Springed: Animation {
    public var options: UIView.AnimationOptions? { animation.options }
    public var timingFunction: CAMediaTimingFunction? { animation.timingFunction }
    public var changes: () -> Void { animation.changes }
}

extension AnimateSpring: DelayedAnimates where Springed: DelayedAnimates { }

// MARK: - Delay

/// Performs an animation after a delay, only to be used in a context where other animations are run simultaneously
public struct AnimateDelayed<Delayed: Animates>: AnimationContainer, DelayedAnimates, AnimatesSimultaneously {
    
    public internal(set) var animation: Delayed
    public var duration: TimeInterval { animation.duration }
    public var totalDuration: TimeInterval { delay + animation.duration }
    
    public let delay: TimeInterval
    
    internal init(delay: TimeInterval, animation: Delayed) {
        self.animation = animation
        self.delay = delay
    }
}

extension AnimateDelayed where Delayed == Animate {
    public init(
        delay: TimeInterval,
        duration: TimeInterval,
        changes: @escaping () -> Void = {}
    ) {
        let animation = Animate(duration: duration, changes: changes)
        self.init(delay: delay, animation: animation)
    }
}

extension AnimateDelayed: SpringAnimates where Delayed: SpringAnimates { }
