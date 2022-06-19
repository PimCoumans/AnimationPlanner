import UIKit

public class RunningSequence {
    
    public let duration: TimeInterval
    public let animations: [SequenceAnimatable]
    
    var remainingAnimations: [Animatable] = []
    var currentAnimation: PerformsAnimations?
    
    var completionHandlers: [(Bool) -> Void] = []
    
    func cancel() {
        print("Cancelling animations")
        
        if let peform = (currentAnimation as? Animation)?.changes {
            
            // 1. Perform animation again to stop animation
            peform()
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
    @discardableResult
    func onCompletion(_ handler: @escaping (_ finished: Bool) -> Void) -> Self {
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
        currentAnimation = nextAnimations.first as? PerformsAnimations
        guard let animation = currentAnimation else {
            complete(finished: true)
            return
        }
        remainingAnimations = Array(nextAnimations.dropFirst())
        
        print("Delay: \(leadingDelay), Animating: \(animation)")
        animation.animate(delay: leadingDelay) { finished in
            guard finished else {
                self.complete(finished: finished)
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
