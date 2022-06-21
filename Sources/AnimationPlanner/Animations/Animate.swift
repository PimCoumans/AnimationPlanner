import UIKit

/// Performs an animation with the provided duration in seconds. Includes properties to set `UIView.AnimationOptions` and
/// even a `CAMediaTimingFunction` to apply to the interpolation of the animated values changed in the ``changes`` closure.
public struct Animate: Animation, SequenceAnimatable, GroupAnimatable {
    public let duration: TimeInterval
    
    public internal(set) var changes: () -> Void
    public internal(set) var options: UIView.AnimationOptions?
    public internal(set) var timingFunction: CAMediaTimingFunction?
    
    /// Creates a new animation, animating the properties updated in the ``changes`` closure
    ///
    /// Only the `duration` parameter is required, all other properties can be added or modified using ``AnimationModifiers``.
    ///
    /// - Tip: AnimationPlanner provides numerous animation curves through a `CAMediaTimingFunction` extension.
    /// Type a period for the `timingFunction` parameter to see what is readily available. Have you tried `.quintOut` yet?
    ///
    /// - Parameters:
    ///   - duration: Duration of animation, measured in seconds
    ///   - timingFunction: Optional `CAMediaTimingFunction` to interpolate animated values with.
    ///   - changes: Closure executed when the animation is performed
    public init(
        duration: TimeInterval,
        timingFunction: CAMediaTimingFunction? = nil,
        changes: @escaping () -> Void = {}
    ) {
        self.duration = duration
        self.timingFunction = timingFunction
        self.changes = changes
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
