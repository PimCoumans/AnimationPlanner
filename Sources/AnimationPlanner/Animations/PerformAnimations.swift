import UIKit

/*
 * -- NOT USED YET, WILL BE IN PHASE 2 --
 */

/// Creates actual `UIView` animations for all animation structs
public protocol PerformsAnimations {
    /// Perform the actual animation
    /// - Parameters:
    ///   - delay: Delay in seconds for how long to wait to actually perform animation
    ///   - completion: Closure called when animation completes
    func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?)
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

extension Spring: PerformsAnimations {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        let delay = (self as? AnimatesDelayed)?.delay ?? 0
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

extension Delayed: Animation, PerformsAnimations where Contained: Animation {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        animation.animate(delay: delay + leadingDelay, completion: completion)
    }
}
