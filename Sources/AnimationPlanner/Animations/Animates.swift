import UIKit

/// Anything that can be animated in AnimationPlanner
public protocol Animates {
    /// Full duration of the animation
    var duration: TimeInterval { get }
}

/// Actual animation that can be used to construct `UIView` animations
public protocol Animation: Animates, PerformsAnimations {
    /// Changes on views to perform animation with
    var changes: () -> Void { get }
    /// Animation options to use for UIView animation
    var options: UIView.AnimationOptions? { get }
    /// Timing function to apply to animation. Leads to the `UIView` animation being performed in a `CATransaction` wrapped animation
    var timingFunction: CAMediaTimingFunction? { get }
}

/// Animation that can be performed in a sequence, meaning each subsequent animation starts right after the previous completes
public protocol AnimatesInSequence: Animates, SequenceAnimatesConvertible { }

extension AnimatesInSequence {
    public func asSequence() -> [AnimatesInSequence] { [self] }
}

/// Animation that can be used in a ``Group`` and be performed simultaneously, meaning all animations run at the same time.
public protocol AnimatesSimultaneously: Animates, SimultaneouslyAnimatesConvertible { }

extension AnimatesSimultaneously {
    public func asGroup() -> [AnimatesSimultaneously] { [self] }
}

/// Adds a delay to the animation
public protocol DelayedAnimates: AnimatesSimultaneously {
    /// Delay in seconds after which the animation should start
    var delay: TimeInterval { get }
    /// Duration of animation without delay applied
    var originalDuration: TimeInterval { get }
}

/// Performs an animation with spring-based parameters
public protocol SpringAnimates: Animates {
    /// Spring damping used for spring-based animation. To quote `UIView`’s animate documentation:
    /// “To smoothly decelerate the animation without oscillation, use a value of 1. Employ a damping ratio closer to zero to increase oscillation.”
    var dampingRatio: CGFloat { get }
    
    /// Initial velocity for spring-based animation. `UIView`‘s documentation clearly explains it with:
    /// “A value of 1 corresponds to the total animation distance traversed in one second. For example, if the total animation distance is 200 points and you want the start of the animation to match a view velocity of 100 pt/s, use a value of 0.5.”
    var initialVelocity: CGFloat { get }
}

/// Perfoms the provided handler in between your actual animations.
/// Typically used for setting up state before an animation or creating side-effects like haptic feedback.
public protocol AnimatesExtra: Animates {
    /// Closure to be executed as this animation should run
    var perform: () -> Void { get }
}
extension AnimatesExtra {
    public var duration: TimeInterval { 0 }
}
