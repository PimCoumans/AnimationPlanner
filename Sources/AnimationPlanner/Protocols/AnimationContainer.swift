import UIKit

/// Adds custom behavior on top of any contained animation. Forwards all required ``Animation`` properties
/// to the contained animation when necessary.
public protocol AnimationContainer {
    /// Animation type contained by ``AnimationContainer``
    associatedtype Contained: Animatable
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

/// Forwarding ``DelayedAnimatable`` properties
extension AnimationContainer where Contained: DelayedAnimatable {
    /// Forwarded ``DelayedAnimatable`` property for ``DelayedAnimatable/delay``
    public var delay: TimeInterval {
        animation.delay
    }
    
    /// Forwarded ``DelayedAnimatable`` property for ``DelayedAnimatable/originalDuration``
    public var originalDuration: TimeInterval {
        animation.originalDuration
    }
}

/// Forwarding ``SpringAnimatable`` properties
extension AnimationContainer where Contained: SpringAnimatable {
    /// Forwarded ``SpringAnimatable`` property for ``SpringAnimatable/dampingRatio``
    public var dampingRatio: CGFloat { animation.dampingRatio }
    /// Forwarded ``SpringAnimatable`` property for ``SpringAnimatable/initialVelocity``
    public var initialVelocity: CGFloat { animation.initialVelocity }
}
