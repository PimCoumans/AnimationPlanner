import UIKit

/// Maintains state about running animations and provides ways to add a completion handler or stop the animations
public class RunningSequence {
    
    public enum State: Equatable {
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
    private(set) var currentAnimation: PerformsAnimations?
    
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
        let stoppabaleStates: [State] = [.ready, .running]
        guard stoppabaleStates.contains(state) else {
            // Only uncompleted sequences can be stopped
            return
        }
        
        state = .stopped
		currentAnimation?.stop()
		currentAnimation = nil
		remainingAnimations
			.compactMap { $0 as? PerformsAnimations }
			.forEach { $0.stop() }
        remainingAnimations.removeAll()
        
        complete(finished: false)
    }
}

extension RunningSequence {
    
    @discardableResult
    func animate(delay: TimeInterval = 0) -> Self {
        guard state == .ready else {
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
        
		guard let animation = impendingAnimations.first as? PerformsAnimations else {
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
        let duration = (animation as? Animatable)?.duration ?? 0
        let completionDuration = duration + leadingDelay
        
        let startTime = CACurrentMediaTime()
        let runningAnimation = animation.animate(delay: leadingDelay) { finished in
            guard finished else {
                self.complete(finished: finished)
                return
            }
            
            guard completionDuration > 0 else {
                // Skip duration checking when animation should immediately complete
                self.animateNextAnimation()
                return
            }
            
            let actualDuration = CACurrentMediaTime() - startTime
            let difference = (duration + leadingDelay) - actualDuration
            let oneFrameDifference: TimeInterval = 1/60
            
            if difference <= 0.1 || actualDuration >= oneFrameDifference {
                self.animateNextAnimation()
            } else {
                // UIView animation probably wasn‘t executed because no actual animatable
                // properties were changed in animation closure. Just wait out remaining time
                // before moving over to the next step.
                let waitTime = max(0, difference - oneFrameDifference) // reduce a frame to be safe
                DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                    self.animateNextAnimation()
                }
            }
        }
        if completionDuration > 0 {
            // Only set current animation when its completion can‘t immediately fire,
            // causing a newer animation to be set as `currentAnimation` right before
            // this line is executed
            currentAnimation = runningAnimation
        }
    }
    
    func complete(finished: Bool) {
        if state == .running {
            state = .completed(finished: finished)
        }
        completionHandlers.forEach { $0(finished) }
        completionHandlers.removeAll()
    }
}
