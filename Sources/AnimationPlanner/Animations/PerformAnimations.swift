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
    ///   - completion: Optional closure called when animation completes
    func animate(delay leadingDelay: TimeInterval, completion: ((_ finished: Bool) -> Void)?)
}

internal protocol ActuallyPerformsAnimations {
    func prepareAnimation(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?)
    func performAnimations(delay totalDelay: TimeInterval, duration: TimeInterval, completion: ((Bool) -> Void)?)
}

extension ActuallyPerformsAnimations where Self: Animatable {
    
    func prepareAnimation(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        var duration = self.duration
        var delay = leadingDelay
        
        if let delayed = self as? DelayedAnimatable {
            duration = delayed.originalDuration
            delay += delayed.delay
        }
        
        self.performAnimations(delay: delay, duration: duration, completion: completion)
    }
}

//extension PerformsAnimations where Self: Animatable {
//    public func animate(delay leadingDelay: TimeInterval, started: (() -> Void)? = nil, completion: ((Bool) -> Void)?) {
//        let duration: TimeInterval
//        let delay: TimeInterval
//
//        if let delayed = self as? DelayedAnimatable {
//            duration = delayed.originalDuration
//            delay = delayed.delay
//        } else {
//            duration = self.duration
//            delay = 0
//        }
//
//        performAnimations(delay: delay, duration: duration, started: started ?? {}, completion: completion)
//    }
//}

extension Animate: PerformsAnimations {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        prepareAnimation(delay: leadingDelay, completion: completion)
    }
}
extension Animate: ActuallyPerformsAnimations {
    func performAnimations(delay totalDelay: TimeInterval, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        let createAnimations: (((Bool) -> Void)?) -> Void = { completion in
            UIView.animate(
                withDuration: duration,
                delay: totalDelay,
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
        prepareAnimation(delay: leadingDelay, completion: completion)
    }
}

extension Extra: ActuallyPerformsAnimations {
    func performAnimations(delay totalDelay: TimeInterval, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        let animation: () -> Void = {
            self.perform()
            completion?(true)
        }
        guard totalDelay > 0 else {
            animation()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            animation()
        }
    }
}

extension AnimateSpring: PerformsAnimations {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        prepareAnimation(delay: leadingDelay, completion: completion)
    }
}
extension AnimateSpring: ActuallyPerformsAnimations {
    func performAnimations(delay totalDelay: TimeInterval, duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(
            withDuration: duration,
            delay: totalDelay,
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
