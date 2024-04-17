import UIKit

/// Performs an animation after a delay, only to be used in a context where other animations are run simultaneously
public struct AnimateDelayed<Delayed: Animatable>: AnimationContainer, DelayedAnimatable, GroupAnimatable {
    
    public internal(set) var animation: Delayed
    
    public var duration: TimeInterval {
        return delay + originalDuration
    }
    
    public var originalDuration: TimeInterval {
        if let delayed = animation as? DelayedAnimatable {
            return delayed.originalDuration
        }
        return animation.duration
    }
    
    public let delay: TimeInterval
    
    internal init(delay: TimeInterval, animation: Delayed) {
        self.animation = animation
        self.delay = delay
    }
}

extension AnimateDelayed where Delayed: DelayedAnimatable {
    public var duration: TimeInterval {
        delay + animation.originalDuration
    }
}

extension AnimateDelayed where Delayed == Animate {
    /// Adds a delay to your animation. Can only be added in a ``Group`` context where animations should be performed simultaneously.
    /// - Parameters:
    ///   - delay: Delay in seconds to add to your animation
    ///   - duration: Duration of animation, measured in seconds
    ///   - changes: Closure executed when the animation is performed
    public init(
        delay: TimeInterval,
        duration: TimeInterval,
        changes: @escaping () -> Void = {}
    ) {
        let animation = Animate(duration: duration, changes: changes)
        self.init(delay: delay, animation: animation)
    }
}

extension AnimateDelayed: Animation where Delayed: Animation { }
extension AnimateDelayed: SpringAnimatable where Delayed: SpringAnimatable { }

extension AnimateDelayed: PerformsAnimations where Contained: PerformsAnimations {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        animation.animate(delay: delay + leadingDelay, completion: completion)
    }
    
    public func stop() {
        animation.stop()
    }
}
