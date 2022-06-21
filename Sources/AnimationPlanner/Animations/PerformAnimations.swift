import UIKit

/// Creates actual `UIView` animations for all animation structs. Implement ``animate(delay:completion:)`` to make sure any custom animation creates an actual animation.
/// Use the default implementation of ``timingParameters(leadingDelay:)-2swvd`` to get the most accurate timing parameters for your animation so any set delay isn't missed.
public protocol PerformsAnimations {
    /// Perform the actual animation
    /// - Parameters:
    ///   - delay: Any delay accumulated (from preceding ``Wait`` structs) leading up to the animation.
    ///   Waits for this amount of seconds before actually performing the animation
    ///   - completion: Optional closure called when animation completes
    func animate(delay leadingDelay: TimeInterval, completion: ((_ finished: Bool) -> Void)?)
    
    /// Queries the animation and possible contained animations to find the correct timing values to use to create an actual animation
    /// - Parameter leadingDelay: Delay to add before performing animation
    /// - Returns: Tuple containing a delay and duration in seconds
    func timingParameters(leadingDelay: TimeInterval) -> (delay: TimeInterval, duration: TimeInterval)
}

extension PerformsAnimations {
    
    public func timingParameters(leadingDelay: TimeInterval) -> (delay: TimeInterval, duration: TimeInterval) {
        var parameters = (delay: leadingDelay, duration: TimeInterval(0))
        
        if let delayed = self as? DelayedAnimatable {
            parameters.delay += delayed.delay
            parameters.duration = delayed.originalDuration
        } else if let animation = self as? Animatable {
            parameters.duration = animation.duration
        }
        return parameters
    }
}

extension Animate: PerformsAnimations {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        let timing = timingParameters(leadingDelay: leadingDelay)
        let createAnimations: (((Bool) -> Void)?) -> Void = { completion in
            UIView.animate(
                withDuration: timing.duration,
                delay: timing.delay,
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
        let timing = timingParameters(leadingDelay: leadingDelay)
        
        let animation: () -> Void = {
            self.perform()
            completion?(true)
        }
        guard timing.delay > 0 else {
            animation()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + timing.delay) {
            animation()
        }
    }
}

extension AnimateSpring: PerformsAnimations {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        let timing = timingParameters(leadingDelay: leadingDelay)
        UIView.animate(
            withDuration: timing.duration,
            delay: timing.delay,
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
