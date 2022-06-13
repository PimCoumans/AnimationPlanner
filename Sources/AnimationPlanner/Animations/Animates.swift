import UIKit

/// Anything that can be animated in AnimationPlanner
public protocol Animates {
    /// Full duration of the animation
    var duration: TimeInterval { get }
}

/// Actual animation that can be used to construct `UIView` animation
public protocol Animation: Animates, PerformsAnimations, AnimationModifiers {
    /// Changes on views to peform animation with
    var changes: () -> Void { get }
    /// Animation options to use for UIView animation
    var options: UIView.AnimationOptions? { get }
    /// Timing function to apply to animation (will use CATransaction wrapped animations)
    var timingFunction: CAMediaTimingFunction? { get }
}

/// Animation that can be performed in sequence, meaning each animation starts right after the previous completes
public protocol AnimatesInSequence: Animates, SequenceAnimatesConvertible { }
extension AnimatesInSequence {
    public func asSequence() -> [AnimatesInSequence] { [self] }
}

/// Animation that can be performed in a simultaneously, meaning each animation is performed simultaniously
public protocol AnimatesSimultaneously: Animates, SimultaneouslyAnimatesConvertible {
    var totalDuration: TimeInterval { get }
}
extension AnimatesSimultaneously {
    public func asGroup() -> [AnimatesSimultaneously] { [self] }
}

/// Perfoms the provided handler in between your actual animations.
/// Typically used for setting up state before an animation or creating side-effects like haptic feedback.
public protocol AnimatesExtra: Animates {
    var perform: () -> Void { get }
}

public protocol AnimatesDelayed: AnimatesSimultaneously {
    var delay: TimeInterval { get }
}
