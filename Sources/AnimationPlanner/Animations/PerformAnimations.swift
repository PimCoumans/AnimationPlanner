import UIKit

/*
 * -- NOT USED YET, WILL BE IN NEXT STEP --
 */

public protocol PerformsAnimations {
    /// Perform the actual animation
    /// - Parameters:
    ///   - delay: Delay in seconds for how long to wait to actually perform animation
    ///   - completion: Closure called when animation completes
    func animate(delay: TimeInterval, completion: ((Bool) -> Void)?)
}

extension Animate: PerformsAnimations {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        let createAnimations: (((Bool) -> Void)?) -> Void = { completion in
            UIView.animate(
                withDuration: duration,
                delay: leadingDelay,
                options: options ?? [],
                animations: changes,
                completion: completion
            )
        }
        
        if let timingFunction = timingFunction {
            CATransaction.begin()
            CATransaction.setAnimationDuration(duration)
            CATransaction.setAnimationTimingFunction(timingFunction)
            
            createAnimations(completion)
            
            CATransaction.commit()
        } else {
            createAnimations(completion)
        }
    }
}

extension AnimateSpring: PerformsAnimations {
    // TODO: Make sure animation container with a spring somewhere also creates a spring
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        UIView.animate(
            withDuration: duration,
            delay: leadingDelay,
            usingSpringWithDamping: dampingRatio,
            initialSpringVelocity: initialVelocity,
            options: animation.options ?? [],
            animations: animation.changes,
            completion: completion
        )
    }
}

extension AnimateDelayed: PerformsAnimations {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        animation.animate(delay: leadingDelay + delay, completion: completion)
    }
}
