import UIKit

/// Anything that can be animated in AnimationPlanner
public protocol Animatable {
    /// Full duration of the animation
    var duration: TimeInterval { get }
}

/// Actual animation that can be used to construct `UIView` animations
public protocol Animation: Animatable, PerformsAnimations {
    /// Changes on views to perform animation with
    var changes: () -> Void { get }
    /// Animation options to use for UIView animation
    var options: UIView.AnimationOptions? { get }
    /// Timing function to apply to animation. Leads to the `UIView` animation being performed in a `CATransaction` wrapped animation
    var timingFunction: CAMediaTimingFunction? { get }
}

/// Animation that can be performed in a sequence, meaning each subsequent animation starts right after the previous completes
public protocol SequenceAnimatable: Animatable, SequenceConvertible { }

extension SequenceAnimatable {
    public func asSequence() -> [SequenceAnimatable] { [self] }
}

/// Animation that can be used in a ``Group`` and be performed simultaneously, meaning all animations run at the same time.
public protocol GroupAnimatable: Animatable, GroupConvertible { }

extension GroupAnimatable {
    public func asGroup() -> [GroupAnimatable] { [self] }
}

/// Adds a delaying functionality to an animation. Delayed animations can only be added in a grouped context, where each animation is performed simultaneously. Adding a delay to a sequence animation can be done by preceding it with a ``Wait`` struct.
public protocol DelayedAnimatable: GroupAnimatable {
    /// Delay in seconds after which the animation should start
    var delay: TimeInterval { get }
    /// Duration of animation without delay applied
    var originalDuration: TimeInterval { get }
}

/// Performs an animation with spring-based parameters
public protocol SpringAnimatable: Animatable {
    /// Spring damping used for spring-based animation. To quote `UIView`’s animate documentation:
    /// “To smoothly decelerate the animation without oscillation, use a value of 1. Employ a damping ratio closer to zero to increase oscillation.”
    var dampingRatio: CGFloat { get }
    
    /// Initial velocity for spring-based animation. `UIView`‘s documentation clearly explains it with:
    /// “A value of 1 corresponds to the total animation distance traversed in one second. For example, if the total animation distance is 200 points and you want the start of the animation to match a view velocity of 100 pt/s, use a value of 0.5.”
    var initialVelocity: CGFloat { get }
}
