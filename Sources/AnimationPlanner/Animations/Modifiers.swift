import UIKit

protocol Mutable {
    func mutate(_ mutator: (inout Self) -> Void) -> Self
}

extension Mutable {
    func mutate(_ mutator: (inout Self) -> Void) -> Self {
       var mutableSelf = self
       mutator(&mutableSelf)
       return mutableSelf
   }
}

protocol AnimationUpdating {
    func updateAnimation(_ animation: Animation) -> Self
}

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

extension Animate: Mutable { }

extension Animate: AnimationModifiers {
    
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

extension Extra: Mutable { }
public protocol DelayModifier {
    func delayed(_ delay: TimeInterval) -> Self
}

extension Extra: DelayModifier {
    public func delayed(_ delay: TimeInterval) -> Extra {
        mutate { $0.delay = delay }
    }
}

/// Contains an Animation, adding custom behaviour
public protocol AnimationContainer: Animation {
    var animation: Animation { get }
}

extension AnimationContainer {
    
    public var duration: TimeInterval {
        animation.duration
    }
    
    public var changes: () -> Void {
        return animation.changes
    }
    
    public var options: UIView.AnimationOptions? {
        return animation.options
    }
    
    public var timingFunction: CAMediaTimingFunction? {
        return animation.timingFunction
    }
}

extension AnimateSpring: Mutable { }
extension AnimateSpring: AnimationUpdating {
    func updateAnimation(_ animation: Animation) -> AnimateSpring {
        mutate { $0.animation = animation }
    }
}

extension AnimateDelayed: Mutable { }
extension AnimateDelayed: AnimationUpdating {
    func updateAnimation(_ animation: Animation) -> AnimateDelayed {
        mutate { $0.animation = animation }
    }
}

extension AnimationContainer {
    
    func castedUpdateAnimation(_ animation: Animation) -> Self {
        // FIXME: This is gross but gets the job done...
        (self as? AnimationUpdating)?.updateAnimation(animation) as! Self
    }
    
    public func timingFunction(_ function: CAMediaTimingFunction) -> Self {
        castedUpdateAnimation(animation.timingFunction(function))
    }
    
    public func options(_ options: UIView.AnimationOptions) -> Self {
        castedUpdateAnimation(animation.options(options))
    }
    
    public func changes(_ changes: @escaping () -> Void) -> Self {
        castedUpdateAnimation(animation.changes(changes))
    }
}

public protocol AnimateSpringModifier {
    func spring(damping: CGFloat, initialVelocity: CGFloat) -> AnimateSpring
}

extension AnimateSpringModifier where Self: Animation {
    public func spring(damping: CGFloat, initialVelocity: CGFloat = 0) -> AnimateSpring {
        AnimateSpring(animation: self, dampingRatio: damping, initialVelocity: initialVelocity)
    }
}

public protocol AnimateDelayModifier {
    func delayed(_ delay: TimeInterval) -> AnimateDelayed
}

extension AnimateDelayModifier where Self: Animation {
    public func delayed(_ delay: TimeInterval) -> AnimateDelayed {
        AnimateDelayed(animation: self, delay: delay)
    }
}

extension Animate: AnimateSpringModifier, AnimateDelayModifier { }
extension AnimateDelayed: AnimateSpringModifier { }
extension AnimateSpring: AnimateDelayModifier { }
