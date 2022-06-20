import UIKit

/*
 * -- NOT USED YET, WILL BE IN PHASE 2 --
 */

/// Creates actual `UIView` animations for all animation structs
public protocol PerformsAnimations {
    /// Perform the actual animation
    /// - Parameters:
    ///   - delay: Any delay accumulated (from preceding ``Wait`` structs) leading up to the animation.
    ///   Waits for this amount of seconds before actually performing the animation
    ///   - completion: Closure called when animation completes
    func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?)
}

extension Animate: PerformsAnimations {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        let duration: TimeInterval
        if let delayed = self as? DelayedAnimatable {
            duration = delayed.originalDuration
        } else {
            duration = self.duration
        }
        
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

extension Extra: PerformsAnimations {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        guard leadingDelay > 0 else {
            perform()
            completion?(true)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + leadingDelay) {
            perform()
            completion?(true)
        }
    }
}

extension AnimateSpring: PerformsAnimations {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        let duration: TimeInterval
        let delay: TimeInterval
        if let delayed = self as? DelayedAnimatable {
            duration = delayed.originalDuration
            delay = delayed.delay
        } else {
            duration = self.duration
            delay = 0
        }
        UIView.animate(
            withDuration: duration,
            delay: leadingDelay + delay,
            usingSpringWithDamping: dampingRatio,
            initialSpringVelocity: initialVelocity,
            options: animation.options ?? [],
            animations: animation.changes,
            completion: completion
        )
    }
}

extension AnimateDelayed: PerformsAnimations where Contained: PerformsAnimations {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        animation.animate(delay: delay + leadingDelay, completion: completion)
    }
}
