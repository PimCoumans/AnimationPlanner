import UIKit

/// Anything that can be animated in AnimationPlanner
public protocol Animates {
    /// Full duration of the animation
    var duration: TimeInterval { get }
}

/// Actual animation that can be used to construct `UIView` animation
public protocol Animation: Animates, PerformsAnimations {
    /// Changes on views to perform animation with
    var changes: () -> Void { get }
    /// Animation options to use for UIView animation
    var options: UIView.AnimationOptions? { get }
    /// Timing function to apply to animation (will use CATransaction wrapped animations)
    var timingFunction: CAMediaTimingFunction? { get }
}

/// Animation that can be performed in a sequence, meaning each subsequent animation starts right after the previous completes
public protocol AnimatesInSequence: Animates, SequenceAnimatesConvertible { }

extension AnimatesInSequence {
    public func asSequence() -> [AnimatesInSequence] { [self] }
}

/// Animation that can be used in a ``Group`` and be performed simultaneously, meaning all animations run at the same time.
public protocol AnimatesSimultaneously: Animates, SimultaneouslyAnimatesConvertible {
    var totalDuration: TimeInterval { get }
}

extension AnimatesSimultaneously {
    public func asGroup() -> [AnimatesSimultaneously] { [self] }
}

/// Adds a delay to the animation
public protocol DelayedAnimates: AnimatesSimultaneously {
    var delay: TimeInterval { get }
}

/// Performs an animation with spring-based parameters
public protocol SpringAnimates: Animates {
    var dampingRatio: CGFloat { get }
    var initialVelocity: CGFloat { get }
}

/// Perfoms the provided handler in between your actual animations.
/// Typically used for setting up state before an animation or creating side-effects like haptic feedback.
public protocol AnimatesExtra: Animates {
    var perform: () -> Void { get }
}
extension AnimatesExtra {
    public var duration: TimeInterval { 0 }
}
extension AnimatesExtra where Self: AnimatesSimultaneously {
    public var totalDuration: TimeInterval { duration }
}
