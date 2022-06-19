import UIKit

/// Performs an animation with the provided duration in seconds. Includes properties to set `UIView.AnimationOptions` and
/// even a `CAMediaTimingFunction` to apply to the interpolation of the animated values changed in the ``changes`` closure.
public struct Animate: Animation, AnimatesInSequence, AnimatesSimultaneously {
    public let duration: TimeInterval
    
    public internal(set) var changes: () -> Void
    public internal(set) var options: UIView.AnimationOptions?
    public internal(set) var timingFunction: CAMediaTimingFunction?
    
    /// Creates a new animation, animating the properties updated in the ``changes`` closure
    ///
    /// Only the `duration` parameter is required, all other properties can be added or modified using ``AnimationModifiers``.
    ///
    /// - Tip: AnimationPlanner provides numerous animation curves through a `CAMediaTimingFunction` extension.
    /// Type a period for the `timingFunction` parameter to see what is readily available. Have you tried `.quintOut` yet?
    ///
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

/// Adds custom behaviour on top of any contained animation. Forwards all required ``Animation`` properties
/// to the contained animation when necessary.
public protocol AnimationContainer {
    /// Animation type contained by ``AnimationContainer``
    associatedtype Contained: Animates
    /// Animation contained any animation using ``AnimationContainer``.
    var animation: Contained { get }
}

/// Forwarding ``Animation`` properties
extension AnimationContainer where Contained: Animation {
    /// Forwarded ``Animation`` property for ``Animate/duration``
    public var duration: TimeInterval { animation.duration }
    /// Forwarded ``Animation`` property for ``Animation/changes``
    public var changes: () -> Void { animation.changes }
    /// Forwarded ``Animation`` property for ``Animation/options``
    public var options: UIView.AnimationOptions? { animation.options }
    /// Forwarded ``Animation`` property for ``Animation/timingFunction``
    public var timingFunction: CAMediaTimingFunction? { animation.timingFunction }
}

/// Forwarding ``DelayedAnimates`` properties
extension AnimationContainer where Contained: DelayedAnimates {
    /// Forwarded ``DelayedAnimates`` property for ``DelayedAnimates/delay``
    public var delay: TimeInterval {
        animation.delay
    }
    
    /// Forwarded ``DelayedAnimates`` property for ``DelayedAnimates/originalDuration``
    public var originalDuration: TimeInterval {
        animation.originalDuration
    }
}

/// Forwarding ``SpringAnimates`` properties
extension AnimationContainer where Contained: SpringAnimates {
    /// Forwarded ``SpringAnimates`` property for ``SpringAnimates/dampingRatio``
    public var dampingRatio: CGFloat { animation.dampingRatio }
    /// Forwarded ``SpringAnimates`` property for ``SpringAnimates/initialVelocity``
    public var initialVelocity: CGFloat { animation.initialVelocity }
}

// MARK: - Spring

/// Performs an animation with spring dampening applied, using the same values as UIView spring animations
public struct AnimateSpring<Springed: Animation>: SpringAnimates, AnimationContainer, AnimatesSimultaneously {
    
    public internal(set) var animation: Springed
    
    public let dampingRatio: CGFloat
    public let initialVelocity: CGFloat
    
    internal init(dampingRatio: CGFloat, initialVelocity: CGFloat, animation: Springed) {
        self.animation = animation
        self.dampingRatio = dampingRatio
        self.initialVelocity = initialVelocity
    }
}

extension AnimateSpring where Springed == Animate {
    /// Creates a spring-based animation with the expected damping and velocity values.
    /// - Parameters:
    ///   - damping: Value between 0 and 1, same as damping ratio used for `UIView`-based spring animations
    ///   - initialVelocity: Relative velocity of animation, defined as full extend of animation per second
    ///   - duration: Duration of animation, measured in seconds
    ///   - changes: Closure executed when the animation is performed
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
    public func asSequence() -> [AnimatesInSequence] { [self] }
}

extension AnimateSpring: Animation where Springed: Animation { }
extension AnimateSpring: DelayedAnimates where Springed: DelayedAnimates { }

// MARK: - Delay

/// Performs an animation after a delay, only to be used in a context where other animations are run simultaneously
public struct AnimateDelayed<Delayed: Animates>: AnimationContainer, DelayedAnimates, AnimatesSimultaneously {
    
    public internal(set) var animation: Delayed
    
    public var duration: TimeInterval {
        return delay + originalDuration
    }
    
    public var originalDuration: TimeInterval {
        if let delayed = animation as? DelayedAnimates {
            return delayed.originalDuration
        }
        return animation.duration
    }
    
    public let delay: TimeInterval
    
    internal init(delay: TimeInterval, animation: Delayed) {
        self.animation = animation
        self.delay = delay
    }
}

extension AnimateDelayed where Delayed: DelayedAnimates {
    public var duration: TimeInterval {
        delay + animation.originalDuration
    }
}

extension AnimateDelayed where Delayed == Animate {
    /// Adds a delay to your animation. Can only be added in a ``Group`` context where animations should be performed simultaneously.
    /// - Parameters:
    ///   - delay: Delay in seconds to add to your animation
    ///   - duration: Duration of animation, measured in seconds
    ///   - changes: Closure executed when the animation is performed
    public init(
        delay: TimeInterval,
        duration: TimeInterval,
        changes: @escaping () -> Void = {}
    ) {
        let animation = Animate(duration: duration, changes: changes)
        self.init(delay: delay, animation: animation)
    }
}

extension AnimateDelayed: Animation where Delayed: Animation { }
extension AnimateDelayed: SpringAnimates where Delayed: SpringAnimates { }
