import UIKit

/// Performs an animation with spring dampening applied, using the same values as UIView spring animations
public struct AnimateSpring<Springed: Animation>: SpringAnimatable, AnimationContainer, GroupAnimatable {
    
    public internal(set) var animation: Springed
    
    public let dampingRatio: CGFloat
    public let initialVelocity: CGFloat
    
    /// Animator used for actually performing the animation
    private var propertyAnimator: UIViewPropertyAnimator?
    
    internal init(dampingRatio: CGFloat, initialVelocity: CGFloat, animation: Springed) {
        self.animation = animation
        self.dampingRatio = dampingRatio
        self.initialVelocity = initialVelocity
    }
}

extension AnimateSpring where Springed == Animate {
    /// Creates a spring-based animation with the expected damping and velocity values.
    /// - Parameters:
    ///   - damping: Value between 0 and 1, same as damping ratio used for `UIView`-based spring animations
    ///   - initialVelocity: Relative velocity of animation, defined as full extend of animation per second
    ///   - duration: Duration of animation, measured in seconds
    ///   - changes: Closure executed when the animation is performed
    public init(
        duration: TimeInterval,
        dampingRatio: CGFloat,
        initialVelocity: CGFloat = 0,
        changes: @escaping () -> Void = {}
    ) {
        let animation = Animate(duration: duration, changes: changes)
        self.init(dampingRatio: dampingRatio, initialVelocity: initialVelocity, animation: animation)
    }
}

extension AnimateSpring: SequenceAnimatable, SequenceConvertible where Contained: SequenceAnimatable {
    public func asSequence() -> [SequenceAnimatable] { [self] }
}

extension AnimateSpring: Animation where Springed: Animation { }
extension AnimateSpring: DelayedAnimatable where Springed: DelayedAnimatable { }

extension AnimateSpring: PerformsAnimations {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) -> PerformsAnimations {
        let timing = timingParameters(leadingDelay: leadingDelay)
        let spring = UISpringTimingParameters(dampingRatio: dampingRatio, initialVelocity: CGVector(dx: initialVelocity, dy: initialVelocity))
        let animator = UIViewPropertyAnimator(duration: timing.duration, timingParameters: spring)
        animator.isUserInteractionEnabled = isUserInteractionEnabled
        animator.addAnimations(changes)
        animator.addCompletion { position in
            completion?(position == .end)
        }
        animator.startAnimation(afterDelay: timing.delay)
        var mutableSelf = self
        mutableSelf.propertyAnimator = animator
        return mutableSelf
    }
    
    public func stop() {
        propertyAnimator?.stopAnimation(true)
    }
}
