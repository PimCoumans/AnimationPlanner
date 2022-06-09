import UIKit

/// Anything that can be animated in AnimationPlanner
public protocol Animates {
    /// Full duration of the animation
    var duration: TimeInterval { get }
}

/// Actual animation that can be used to construct `UIView` animation
public protocol Animation: Animates, PerformsAnimations, AnimationModifiers {
    var changes: () -> Void { get }
    var options: UIView.AnimationOptions? { get }
    var timingFunction: CAMediaTimingFunction? { get }
}

/// Animation that can be performed in sequence, meaning each animation starts right after the previous completes
public protocol SequenceAnimates: Animates { }

/// Animation that should be performed in a group, meaning each animation is performed simultaniously
public protocol GroupAnimates: Animates { }

/// Performs an animation with for the provided duration in seconds, with an
public struct Animate: Animation, SequenceAnimates, GroupAnimates {
    public let duration: TimeInterval
    
    public internal(set) var changes: () -> Void
    public internal(set) var options: UIView.AnimationOptions?
    public internal(set) var timingFunction: CAMediaTimingFunction?
    
    public init(duration: TimeInterval, changes: @escaping () -> Void = { }) {
        self.duration = duration
        self.changes = changes
    }
}

public struct Wait: SequenceAnimates {
    public let duration: TimeInterval
    
    public init(_ duration: TimeInterval) {
        self.duration = duration
    }
}

public struct Extra: SequenceAnimates, GroupAnimates {
    public let duration: TimeInterval = 0
    public internal(set) var delay: TimeInterval
    public let perform: () -> Void
    
    public init(delay: TimeInterval = 0, perform: @escaping () -> Void) {
        self.perform = perform
        self.delay = delay
    }
}

public struct AnimateSpring: AnimationContainer, SequenceAnimates, GroupAnimates {
    
    public internal(set) var animation: Animation
    
    public let dampingRatio: CGFloat
    public let initialVelocity: CGFloat
    
    internal init<T: Animation>(animation: T, dampingRatio: CGFloat, initialVelocity: CGFloat) {
        self.animation = animation
        self.dampingRatio = dampingRatio
        self.initialVelocity = initialVelocity
    }
    
    public init(duration: TimeInterval, damping: CGFloat, velocity: CGFloat = 0, changes: @escaping () -> Void) {
        let animation = Animate(duration: duration, changes: changes)
        self.init(animation: animation, dampingRatio: damping, initialVelocity: velocity)
    }
}

public struct AnimateDelayed: AnimationContainer, GroupAnimates {
    
    public internal(set) var animation: Animation
    
    public let delay: TimeInterval
    
    internal init<T: Animation>(animation: T, delay: TimeInterval) {
        self.animation = animation
        self.delay = delay
    }
    
    public init(duration: TimeInterval, delay: TimeInterval, changes: @escaping () -> Void) {
        let animation = Animate(duration: duration, changes: changes)
        self.init(animation: animation, delay: delay)
    }
}
