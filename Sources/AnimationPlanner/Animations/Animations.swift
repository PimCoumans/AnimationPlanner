import UIKit

/// Performs an animation with for the provided duration in seconds, with an
public struct Animate: Animation, AnimatesInSequence, AnimatesSimultaneously {
    public let duration: TimeInterval
    public var totalDuration: TimeInterval { duration }
    
    public internal(set) var changes: () -> Void
    public internal(set) var options: UIView.AnimationOptions?
    public internal(set) var timingFunction: CAMediaTimingFunction?
    
    public init(duration: TimeInterval, changes: @escaping () -> Void = { }) {
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
    public var duration: TimeInterval = 0
    public var totalDuration: TimeInterval = 0
    
    public var perform: () -> Void
    public init(perform: @escaping () -> Void) {
        self.perform = perform
    }
}

/// Perfoms the provided handler after the specified delay.
/// Typically used for setting up state before an animation or creating side-effects like haptic feedback.
public struct ExtraDelayed: AnimatesExtra, AnimatesDelayed {
    public var duration: TimeInterval { delay }
    public var totalDuration: TimeInterval { duration }
    public let delay: TimeInterval
    
    public let perform: () -> Void
    
    public init(delay: TimeInterval = 0, perform: @escaping () -> Void) {
        self.delay = delay
        self.perform = perform
    }
}

/// Adds custom behaviour on top of the contained animation. Forwards all required `Animation` properties to the contained animation
public protocol AnimationContainer: Animation {
    var animation: Animation { get }
}

extension AnimationContainer {
    public var duration: TimeInterval { animation.duration }
    public var changes: () -> Void { animation.changes }
    public var options: UIView.AnimationOptions? { animation.options }
    public var timingFunction: CAMediaTimingFunction? { animation.timingFunction }
}

/// Performs an animation with spring dampening applied, using the same values as UIView spring animations
public struct AnimateSpring: AnimationContainer, AnimatesInSequence, AnimatesSimultaneously {
    public internal(set) var animation: Animation
    public var totalDuration: TimeInterval { duration }
    
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

/// Performs an animation after a delay, only to be used in a context where other animations are run simultaneously
public struct AnimateDelayed: AnimationContainer, AnimatesDelayed {
    public internal(set) var animation: Animation
    public var totalDuration: TimeInterval {
        delay + animation.duration
    }
    
    public let delay: TimeInterval
    
    internal init<T: Animation>(delay: TimeInterval, animation: T) {
        self.delay = delay
        self.animation = animation
    }
    
    public init(delay: TimeInterval, duration: TimeInterval, changes: @escaping () -> Void) {
        let animation = Animate(duration: duration, changes: changes)
        self.init(delay: delay, animation: animation)
    }
}
