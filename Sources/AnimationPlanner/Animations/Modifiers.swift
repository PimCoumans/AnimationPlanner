import UIKit

// Adds modifier functions to animations
public protocol AnimationModifiers {
    /// Add animation options to the animation
    /// - Parameter options: OptionSet of UIView AnimationOptions
    /// - Note: Using `.repeats` will break expected behavior when used in a sequence
    func options(_ options: UIView.AnimationOptions) -> Self
    
    /// Apply timing function to the animation
    ///
    /// Overrides any animation curves set with ``options(_:)``
    /// - Parameter function: Custom CAMediaTimingFunction or any of the avaialble static extensions
    func timingFunction(_ function: CAMediaTimingFunction) -> Self
    
    /// Add or update the changes made during the animation
    /// - Parameter changes: Change your `UIView` properties in this closure
    /// - Note: This replaces any previous animations set
    func changes(_ changes: @escaping () -> Void) -> Self
}

/// Adds spring interpolation to an existing animation
public protocol SpringModifier {
    func spring(damping: CGFloat, initialVelocity: CGFloat) -> AnimateSpring
}

extension SpringModifier where Self: Animation {
    public func spring(damping: CGFloat, initialVelocity: CGFloat = 0) -> AnimateSpring {
        // By default, all structs conforming `Animation` should be able to animate with a spring
        AnimateSpring(animation: self, dampingRatio: damping, initialVelocity: initialVelocity)
    }
}

// Add a delay to the animation
public protocol DelayModifier {
    associatedtype DelayedAnimation: Animates
    func delayed(_ delay: TimeInterval) -> DelayedAnimation
}

extension DelayModifier where Self: Animation {
    public func delayed(_ delay: TimeInterval) -> AnimateDelayed {
        AnimateDelayed(delay: delay, animation: self)
    }
}

extension Animate: AnimationModifiers, SpringModifier, DelayModifier { }
extension AnimateDelayed: AnimationModifiers, SpringModifier { }
extension AnimateSpring: AnimationModifiers, DelayModifier { }

extension Extra: DelayModifier {
    public func delayed(_ delay: TimeInterval) -> ExtraDelayed {
        ExtraDelayed(delay: delay, perform: perform)
    }
}

/* -- Internal animation modifying convenience methods -- */

/// Convenience protocol to let structs to change properties on themself without using `mutating`
protocol Mutable {
    mutating func mutate(_ mutator: (inout Self) -> Void) -> Self
}

extension Mutable {
    func mutate(_ mutator: (inout Self) -> Void) -> Self {
       var mutableSelf = self
       mutator(&mutableSelf)
       return mutableSelf
   }
}

extension Animate: Mutable {
    public func options(_ options: UIView.AnimationOptions) -> Self {
        mutate { $0.options = options }
    }
    public func timingFunction(_ function: CAMediaTimingFunction) -> Self {
        mutate { $0.timingFunction = function}
    }
    public func changes(_ changes: @escaping () -> Void) -> Animate {
        mutate { $0.changes = changes }
    }
}

extension AnimateSpring: Mutable {
    public func options(_ options: UIView.AnimationOptions) -> Self {
        mutate { $0.animation = animation.options(options) }
    }
    public func timingFunction(_ function: CAMediaTimingFunction) -> Self {
        mutate { $0.animation = animation.timingFunction(function) }
    }
    public func changes(_ changes: @escaping () -> Void) -> Self {
        mutate { $0.animation = animation.changes(changes) }
    }
}

extension AnimateDelayed: Mutable {
    public func options(_ options: UIView.AnimationOptions) -> Self {
        mutate { $0.animation = animation.options(options) }
    }
    public func timingFunction(_ function: CAMediaTimingFunction) -> Self {
        mutate { $0.animation = animation.timingFunction(function) }
    }
    public func changes(_ changes: @escaping () -> Void) -> Self {
        mutate { $0.animation = animation.changes(changes) }
    }
}
