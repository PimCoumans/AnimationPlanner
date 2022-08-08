import UIKit

/// Adds modifier methods to animations, providing a way to update multiple properties with chained successive method calls.
///
/// Each method can be called on your animation. All animations conforming to `AnimationModifiers` should at least implement the following methods:
/// - ``options(_:)``: Set the `UIView.AnimationOptions` for the animation. Will append new options to any existing options.
/// - ``timingFunction(_:)``: Sets a `CAMediaTimingFunction` for the animation. Overwrites possible previously set functions.
/// - ``changes(_:)``: Sets the ``Animation/changes`` to be performed for your animation.
public protocol AnimationModifiers: Animation {
    /// Set the `UIView.AnimationOptions` for the animation. Will append new options to any existing options.
    ///
    /// Deprecated as most options (like transitions and repeating) aren‘t supported for AnimationPlanner‘s use case and
    /// using specific modifier functions for animation options reads better.
    ///
    /// - Parameter options: OptionSet of UIView AnimationOptions
    /// - Note: Using `.repeats` will break expected behavior when used in a sequence
    @available(*, deprecated, message: "Use the modifier functions as `allowUserinteraction` to modify your animation")
    func options(_ options: UIView.AnimationOptions) -> Self
    
    /// Enables interaction on your parent views while this animation is running
    func allowUserInteraction() -> Self
    
    /// Sets a `CAMediaTimingFunction` for the animation. Overwrites possible previously set functions.
    ///
    /// Overrides any animation curves previously set with ``timingFunction(_:)``
    ///
    /// - Tip: AnimationPlanner provides numerous animation curves through a `CAMediaTimingFunction` extension.
    /// Type a period for the `timingFunction` parameter to see what is readily available. Have you tried `.quintOut` yet?
    ///
    /// - Important: Timing functions are ignored when applied to an animation using spring interpolation (``AnimateSpring``)
    ///
    /// - Parameter function: Custom CAMediaTimingFunction or any of the avaialble static extensions
    func timingFunction(_ function: CAMediaTimingFunction) -> Self
    
    /// Sets the ``Animation/changes`` to be performed for your animation. Could be used when it‘s convenient to add your animation changes at a later state, e.g., after applying other modifiers to your ``Animate`` struct.
    /// - Parameter changes: Change properties to animate in this closure
    /// - Note: This replaces any previous animation changes set
    func changes(_ changes: @escaping () -> Void) -> Self
}

extension Animate: AnimationModifiers {
    public func options(_ options: UIView.AnimationOptions) -> Self {
        // Update options by creating a union of existing options
        mutate { $0.options = $0.options?.union(options) ?? options }
    }
    public func allowUserInteraction() -> Animate {
        mutate { $0.allowsUserInteraction = true }
    }
    public func timingFunction(_ function: CAMediaTimingFunction) -> Self {
        mutate { $0.timingFunction = function}
    }
    public func changes(_ changes: @escaping () -> Void) -> Animate {
        mutate { $0.changes = changes }
    }
}

// MARK: - Spring modifiers

/// Adds spring interpolation to an existing animation
public protocol SpringModifier {
    /// Animation contained by ``AnimateSpring`` animation
    associatedtype SpringedAnimation: Animation
    
    /// Creates a spring-based animation with the expected damping and velocity values. Timing curves are ignored with spring animations as the spring itself should do all the interpolating.
    /// - Parameters:
    ///   - damping: Value between 0 and 1, same as damping ratio used for `UIView`-based spring animations
    ///   - initialVelocity: Relative velocity of animation, defined as full extend of animation per second
    /// - Returns: ``AnimateSpring``-contained animation appending spring values to the modified animation
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

/// Adds a delay to an existing animation
public protocol DelayModifier {
    /// Animation contained by ``AnimateDelayed`` animation
    associatedtype DelayedAnimation: Animatable
    /// Adds a delay to your animation. Only available in a ``Group`` context where animations should be performed simultaneously.
    /// - Parameter delay: Delay in seconds to add to your animation.
    /// - Returns: `AnimateDelayed`-contained animation adding a delay the modified animation
    func delayed(_ delay: TimeInterval) -> AnimateDelayed<DelayedAnimation>
}

extension DelayModifier where Self: GroupAnimatable {
    public func delayed(_ delay: TimeInterval) -> AnimateDelayed<Self> {
        // By default, all structs conforming to `GroupAnimatable` should be able to animate with a delay
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

extension Animate: Mutable { }
extension Extra: Mutable { }

extension AnimateSpring: Mutable { }
extension AnimateSpring: AnimationModifiers where Contained: AnimationModifiers {
    func modifyAnimation(_ handler: (Contained) -> Contained) -> Self {
        mutate { $0.animation = handler(animation) }
    }
    
    @available(*, deprecated, message: "Use the modifier functions as `allowUserinteraction` to modify your animation")
    public func options(_ options: UIView.AnimationOptions) -> Self {
        modifyAnimation { $0.options(options) }
    }
    public func allowUserInteraction() -> AnimateSpring<Springed> {
        modifyAnimation { $0.allowUserInteraction() }
    }
    public func timingFunction(_ function: CAMediaTimingFunction) -> Self {
        modifyAnimation { $0.timingFunction(function) }
    }
    public func changes(_ changes: @escaping () -> Void) -> Self {
        modifyAnimation { $0.changes(changes) }
    }
}

extension AnimateDelayed: Mutable { }
extension AnimateDelayed: AnimationModifiers where Contained: Animation & AnimationModifiers {
    func modifyAnimation(_ handler: (Contained) -> Contained) -> Self {
        mutate { $0.animation = handler(animation) }
    }
    
    @available(*, deprecated, message: "Use the modifier functions as `allowUserinteraction` to modify your animation")
    public func options(_ options: UIView.AnimationOptions) -> Self {
        modifyAnimation { $0.options(options) }
    }
    public func allowUserInteraction() -> AnimateDelayed<Delayed> {
        modifyAnimation { $0.allowUserInteraction() }
    }
    public func timingFunction(_ function: CAMediaTimingFunction) -> Self {
        modifyAnimation { $0.timingFunction(function) }
    }
    public func changes(_ changes: @escaping () -> Void) -> Self {
        modifyAnimation { $0.changes(changes) }
    }
}
