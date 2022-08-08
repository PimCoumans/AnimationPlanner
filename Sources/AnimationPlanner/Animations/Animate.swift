import UIKit

/// Performs an animation with the provided duration in seconds. Includes properties to set `UIView.AnimationOptions` and
/// even a `CAMediaTimingFunction` to apply to the interpolation of the animated values changed in the ``changes`` closure.
public struct Animate: Animation, SequenceAnimatable, GroupAnimatable {
    public let duration: TimeInterval
    
    public internal(set) var changes: () -> Void
    public internal(set) var options: UIView.AnimationOptions?
    public internal(set) var timingFunction: CAMediaTimingFunction?
    public internal(set) var allowsUserInteraction: Bool = false
    
    /// Animator used for actually performing the animation
    private var propertyAnimator: UIViewPropertyAnimator?
    
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
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) -> PerformsAnimations {
        let timing = timingParameters(leadingDelay: leadingDelay)
		var mutableSelf = self
		let animator: UIViewPropertyAnimator
		if let function = timingFunction {
			animator = UIViewPropertyAnimator(duration: timing.duration, timingFunction: function, animations: changes)
            animator.isUserInteractionEnabled = isUserInteractionEnabled
			animator.addCompletion { position in
				completion?(position == .end)
			}
			animator.startAnimation(afterDelay: timing.delay)
		} else {
			animator = UIViewPropertyAnimator.runningPropertyAnimator(
				withDuration: timing.duration,
				delay: timing.delay,
				options: options ?? [],
				animations: changes,
				completion: { position in
					completion?(position == .end)
				}
			)
		}
		mutableSelf.propertyAnimator = animator
		return mutableSelf
    }
	
	public func stop() {
		propertyAnimator?.stopAnimation(true)
	}
}
