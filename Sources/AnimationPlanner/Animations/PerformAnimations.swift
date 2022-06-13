import UIKit

/*
 * -- NOT USED YET, WILL BE IN NEXT STEP --
 */

/// Creates actual `UIView` animations for all animation structs
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

extension AnimationContainer {
    
    func containedAnimations<T: Animation>(where predicate: ((T) -> Bool)? = nil) -> [T] {
        var containedAnimations = [Animation]()
        
        var animation: Animation? = self
        while let foundAnimation = animation {
            containedAnimations.append(foundAnimation)
            animation = (foundAnimation as? AnimationContainer)?.animation
        }
        
        return containedAnimations
            .reversed()
            .compactMap { $0 as? T }
            .filter(predicate ?? { _ in true })
    }
    
    func containedAnimation<T: Animation>(where predicate: ((T) -> Bool)? = nil) -> T? {
        return containedAnimations().first
    }
    
    var springAnimation: AnimateSpring? {
        containedAnimation()
    }
    
    var totalDelay: TimeInterval {
        let delayedAnimations: [AnimateDelayed] = containedAnimations()
        return delayedAnimations.reduce(0, { $0 + $1.delay })
    }
}

extension AnimationContainer {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        let totalDelay = self.totalDelay
        if let springAnimation = springAnimation {
            // Use found spring animation to perform animation with delay
            springAnimation.animate(delay: leadingDelay + totalDelay, completion: completion)
        } else {
            // Pas on to contained animation where eventually ``Animate`` will perform animation
            animation.animate(delay: leadingDelay + totalDelay, completion: completion)
        }
    }
}

extension AnimateSpring: PerformsAnimations {
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
