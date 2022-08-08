import UIKit

/// Creates actual `UIView` animations for all animation structs. Implement ``animate(delay:completion:)`` to make sure any custom animation creates an actual animation.
/// Use the default implementation of ``timingParameters(leadingDelay:)-2swvd`` to get the most accurate timing parameters for your animation so any set delay isn't missed.
public protocol PerformsAnimations {
    /// Perform the actual animation
    /// - Parameters:
    ///   - delay: Any delay accumulated (from preceding ``Wait`` structs) leading up to the animation.
    ///   Waits for this amount of seconds before actually performing the animation
    ///   - completion: Optional closure called when animation completes
    @discardableResult
    func animate(delay leadingDelay: TimeInterval, completion: ((_ finished: Bool) -> Void)?) -> PerformsAnimations
    
    /// Cancels any currently running animations
    func stop()
    
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
