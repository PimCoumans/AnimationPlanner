import UIKit

/// Maintains state about running animations and provides ways to add a completion handler or stop the animations
public class RunningSequence {
    
    public enum State {
        /// Sequence is ready but not yet running animations
        case ready
        /// Sequence is performing animations
        case running
        /// Sequence has completed animations have completed
        /// - Parameter finished: Wether animations have properly finished
        case completed(finished: Bool)
        /// Sequence has been manually stopped
        case stopped
    }
    
    /// Total duration of all animations in sequence
    public let duration: TimeInterval
    /// All animation to be performed in sequence
    public let animations: [SequenceAnimatable]
    
    /// Current state of sequence
    public private(set) var state: State = .ready
    
    private(set) var remainingAnimations: [Animatable] = []
    private(set) var currentAnimation: Animatable?
    
    private(set) var completionHandlers: [(Bool) -> Void] = []
    
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
        switch state {
            
        case .ready: fallthrough
        case .running:
            completionHandlers.append(handler)
        case .completed(finished: let finished):
            handler(finished)
        case .stopped:
            handler(false)
        }
        return self
    }
}

public extension RunningSequence {
    /// Stops the currently running animation and cancels any upcoming animations
    func stopAnimations() {
        guard case .running = state else {
            // Only running animations can be stopped
            return
        }
        
        state = .stopped
        if let animation = currentAnimation as? Animation {
            // Perform animation’s changes again to stop animation
            animation.changes()
        }
        
        remainingAnimations.removeAll()
        currentAnimation = nil
        
        complete(finished: false)
    }
}

extension RunningSequence {
    
    @discardableResult
    func animate(delay: TimeInterval = 0) -> Self {
        guard case .ready = state else {
            // Don’t start animating a sequence with running, completed or stopped animations
            return self
        }
        state = .running
        remainingAnimations = Array(animations)
        animateNextAnimation(initialDelay: delay)
        return self
    }
    
    func animateNextAnimation(initialDelay: TimeInterval = 0) {
        var leadingDelay: TimeInterval = initialDelay
        let impendingAnimations = remainingAnimations.drop { animation in
            if let wait = animation as? Wait {
                leadingDelay += wait.duration
                return true
            }
            guard animation is PerformsAnimations else {
                return true
            }
            return false
        }
        
        currentAnimation = impendingAnimations.first
        guard let animation = currentAnimation as? PerformsAnimations else {
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
        
        remainingAnimations = Array(impendingAnimations.dropFirst())
        let startTime = CACurrentMediaTime()
        
        animation.animate(delay: leadingDelay) { finished in
            guard finished else {
                self.complete(finished: finished)
                return
            }
            
            if let duration = (animation as? Animatable)?.duration {
                let actualDuration = CACurrentMediaTime() - startTime
                let difference = (duration + leadingDelay) - actualDuration
                let oneFrameDifference: TimeInterval = 1/60
                
                if difference > 0.1 && actualDuration < oneFrameDifference {
                    // UIView animation probably wasn‘t executed because no actual animatable
                    // properties were changed in animation closure. Just wait out remaining time
                    // before moving over to the next step.
                    let waitTime = max(0, difference - oneFrameDifference) // reduce a frame to be safe
                    DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                        self.animateNextAnimation()
                    }
                    return
                }
            }
            self.animateNextAnimation()
        }
    }
    
    func complete(finished: Bool) {
        if case .running = state {
            state = .completed(finished: finished)
        }
        completionHandlers.forEach { $0(finished) }
        completionHandlers.removeAll()
    }
}
