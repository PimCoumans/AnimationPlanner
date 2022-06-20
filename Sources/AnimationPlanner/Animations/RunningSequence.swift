import UIKit

/// Maintains state about running animations and provides ways to add a completion handler or stop the animations
public class RunningSequence {
    
    public let duration: TimeInterval
    public let animations: [SequenceAnimatable]
    
    var remainingAnimations: [Animatable] = []
    var currentAnimation: (PerformsAnimations & Animatable)? // FIXME: Yikes
    
    var completionHandlers: [(Bool) -> Void] = []
    
    /// Stops the currently running animation and stops any upcoming animations
    public func stopAnimations() {
        if let animatingChanges = (currentAnimation as? Animation)?.changes {
            
            // 1. Perform animation again to stop animation
            animatingChanges()
        }
        
        // 2. Clear remaining
        remainingAnimations.removeAll()
        
        // 3. Call completion handler(s) with finished = false
        completionHandlers.forEach { $0(false) }
        completionHandlers.removeAll()
    }
    
    internal init(animations: [SequenceAnimatable]) {
        self.animations = animations
        self.duration = animations.reduce(0, { $0 + $1.duration })
    }
}

public extension RunningSequence {
    /// Adds completion handler to running sequence. The closure is called when the sequence has completed
    /// - Parameter handler: Closure to be executed when sequence has finished
    /// - Returns: Returns `Self` so this method can be added directly after creation an animation sequence
    @discardableResult
    func onComplete(_ handler: @escaping (_ finished: Bool) -> Void) -> Self {
        completionHandlers.append(handler)
        return self
    }
}

extension RunningSequence {
    
    func animate(delay: TimeInterval = 0) {
        remainingAnimations = Array(animations)
        animateNextAnimation(initialDelay: delay)
    }
    
    func animateNextAnimation(initialDelay: TimeInterval = 0) {
        var leadingDelay: TimeInterval = initialDelay
        let nextAnimations = remainingAnimations.drop { animation in
            if let wait = animation as? Wait {
                leadingDelay += wait.duration
                return true
            }
            guard animation is PerformsAnimations else {
                return true
            }
            return false
        }
        currentAnimation = nextAnimations.first as? (PerformsAnimations & Animatable)
        guard let animation = currentAnimation else {
            guard leadingDelay == 0 else {
                // Wait out the remaing delay until calling completion closure
                DispatchQueue.main.asyncAfter(deadline: .now() + leadingDelay) {
                    self.complete(finished: true)
                }
                return
            }
            complete(finished: true)
            return
        }
        
        remainingAnimations = Array(nextAnimations.dropFirst())
        let startTime = CACurrentMediaTime()
        
        animation.animate(delay: leadingDelay) { finished in
            guard finished else {
                self.complete(finished: finished)
                return
            }
            
            let actualDuration = CACurrentMediaTime() - startTime
            let difference = (animation.duration + leadingDelay) - actualDuration
            let oneFrameDifference: TimeInterval = 1/60
            
            guard difference <= 0.1 || actualDuration > oneFrameDifference else {
                // UIView animation probably wasn‘t executed because no actual animatable
                // properties were changed in animation closure. Just wait out remaining time
                // before moving over to the next step.
                let waitTime = max(0, difference - oneFrameDifference) // reduce a frame to be safe
                DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                    self.animateNextAnimation()
                }
                return
            }
            self.animateNextAnimation()
        }
    }
    
    func complete(finished: Bool) {
        completionHandlers.forEach { $0(finished) }
        completionHandlers.removeAll()
    }
}
