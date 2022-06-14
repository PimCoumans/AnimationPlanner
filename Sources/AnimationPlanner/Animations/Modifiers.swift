import UIKit

// Adds modifier functions to animations
public protocol AnimationModifiers: Animation {
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

extension Animate: AnimationModifiers { }

// MARK: - Spring modifiers

/// Adds spring interpolation to an existing animation
public protocol SpringModifier {
    associatedtype SpringedAnimation: Animation
    func spring(damping: CGFloat, initialVelocity: CGFloat) -> AnimateSpring<SpringedAnimation>
}

extension SpringModifier where Self: Animation {
    public func spring(damping: CGFloat, initialVelocity: CGFloat = 0) -> AnimateSpring<Self> {
        // By default, all structs conforming `Animation` should be able to animate with a spring
        AnimateSpring(dampingRatio: damping, initialVelocity: initialVelocity, animation: self)
    }
}

extension AnimateDelayed: SpringModifier where Contained: Animation {
    public func spring(damping: CGFloat, initialVelocity: CGFloat) -> AnimateSpring<Contained> {
        AnimateSpring(dampingRatio: damping, initialVelocity: initialVelocity, animation: animation)
    }
}

extension Animate: SpringModifier { }

// MARK: - Delay modifiers

// Add a delay to the animation
public protocol DelayModifier {
    associatedtype DelayedAnimation: Animates
    func delayed(_ delay: TimeInterval) -> AnimateDelayed<DelayedAnimation>
}

extension DelayModifier where Self: AnimatesSimultaneously {
    public func delayed(_ delay: TimeInterval) -> AnimateDelayed<Self> {
        // By default, all structs conforming to `AnimatesSimultaneously` should be able to animate with a delay
        AnimateDelayed(delay: delay, animation: self)
    }
}

extension Animate: DelayModifier { }

extension AnimateSpring: DelayModifier { }

extension Extra: DelayModifier { }

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

extension AnimateSpring: Mutable { }
extension AnimateSpring: AnimationModifiers where Contained: AnimationModifiers {
    func modifyAnimation(_ handler: (AnimationModifiers) -> Contained) -> Self {
        mutate { $0.animation = handler(animation) }
    }
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

extension AnimateDelayed: Mutable { }
extension AnimateDelayed: AnimationModifiers where Contained: Animation & AnimationModifiers {
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
