import UIKit

public protocol StepAnimatable {
    
    /// Start a sequence where you add each step in the `addSteps` closure. Use the provided `Sequence` object
    /// to add each step which should either be an actual animation or a delay.
    /// The `completion` closure is executed when the last animation has finished.
    /// - Parameters:
    ///   - addSteps: Closure used to add steps to the provided `Sequence` object
    ///   - completion: Executed when the last animation has finished.
    static func animateSteps(_ addSteps: (AnimationSequence) -> Void, completion: ((Bool) -> Void)?)

    /// Start a group animation where you add each animation is performed concurrently. Use the provided `Group` object
    /// to add each animation.
    /// The `completion` closure is executed when the last animation has finished.
    /// - Parameters:
    ///   - addAnimations: Closure used to add animations to the provided `Group` object
    ///   - completion: Executed when the longest animation has finished.
    static func animateGroup(_ addAnimations: (AnimationSequence.Group) -> Void, completion: ((Bool) -> Void)?)
}

private protocol Animatable {
    var duration: TimeInterval { get }
    func animate(withDelay delay: TimeInterval, completion: ((Bool) -> Void)?)
}

/// Prepared for a future update, where this is returned after starting a sequence
/// so a progress can be polled and the full sequence can be cancelled
//private class RunningAnimation {
//    var duration: TimeInterval = 0
//    private(set) var remainingSteps: [AnimationSequence.Step] = []
//
//    /// Should cancel any animations not yet started
//    func cancel() {
//
//    }
//}

public class AnimationSequence {
    
    /// All steps currently added to the sequence
    public fileprivate(set) var steps: [Step] = []
    
    /// A step for each animation in the sequence.
    public enum Step {
        /// A step that merely adds a delay, accumulated for the next step with actual animations
        /// - Parameter duration: Duration of the delay in seconds
        case delay(duration: TimeInterval)
        
        /// An animation step that results in a `UIView.animate()` call with all the necessary options
        /// - Parameter duration: Duration of the animation
        /// - Parameter delay: Delay for the animation, only used in some specific cases
        /// - Parameter options: Animation options, when `.repeats` make sure to set a limit or any subsequent next step might not be executed
        /// - Parameter timingFunction: `CAMediaTimingFunction` to apply to animation, will wrap animation in `CATransaction`
        /// - Parameter animations: Closure in which values to animate should be changed
        case animation(
            duration: TimeInterval,
            delay: TimeInterval,
            options: UIView.AnimationOptions = [],
            timingFunction: CAMediaTimingFunction? = nil,
            animations: () -> Void)
        
        /// Step that contains group of animation steps, all of which should be performed simultaniously
        /// - Parameter animations: All the steps to animate at the same time
        case group(animations: [Self])
        
        /// Only used in animation groups, where an animation in the group can
        /// be another sequence
        case sequence(sequence: AnimationSequence)
    }
}

extension AnimationSequence {
    
    /// Adds an animation to the sequence with all the available options.
    ///
    /// Adding each steps can by done in a chain, as this method returns `Self`
    /// - Note: Adding a timing function will wrap the animation in a `CATransaction` commit
    /// - Parameters:
    ///   - duration: How long the animation should last
    ///   - options: Options to use for the animation
    ///   - timingFunction: `CAMediaTimingFunction` to use for animation
    ///   - animations: Closure in which values to animate should be changed
    /// - Returns: Returns self, enabling the use of chaining mulitple calls
    @discardableResult public func add(
        duration: TimeInterval,
        options: UIView.AnimationOptions = [],
        timingFunction: CAMediaTimingFunction? = nil,
        animations: @escaping () -> Void
    ) -> Self {
        steps.append(
            .animation(duration: duration, delay: 0, options: options, timingFunction: timingFunction, animations: animations)
        )
        return self
    }
    
    /// Adds a delay to the animation sequence
    ///
    /// While this adds an actual step to the sequence, in practice the next step that actually does
    /// the animation will use the delay of the previous steps (or all previous delays leading up to that step)
    /// - Parameter delay: Duration of the delay
    /// - Returns: Returns self, enabling the use of chaining mulitple calls
    @discardableResult public func delay(_ duration: TimeInterval) -> Self {
        steps.append(
            .delay(duration: duration)
        )
        return self
    }
}

extension AnimationSequence {
    
    /// Group of animation steps, all of which should be performed simultaniously
    public class Group {
        
        /// All animations currently added to the sequence
        public private(set) var animations: [Step] = []
        
        /// Adds an animation to the animation group with all the available options.
        ///
        /// Adding each part in the group can by done in a chain, as this method returns `Self`
        /// - Note: Adding a timing function will wrap the animation in a `CATransaction` commit
        /// - Parameters:
        ///   - duration: Amount of time (in seconds)  the animation should last
        ///   - delay: Amount of time (in seconds) the animation should wait to start
        ///   - options: Options to use for the animation
        ///   - timingFunction: `CAMediaTimingFunction` to use for animation
        ///   - animations: Closure in which values to animate should be changed
        /// - Returns: Returns self, enabling the use of chaining mulitple calls
        @discardableResult public func animate(
            duration: TimeInterval,
            delay: TimeInterval = 0,
            options: UIView.AnimationOptions = [],
            timingFunction: CAMediaTimingFunction? = nil,
            animations: @escaping () -> Void
        ) -> Self {
            self.animations.append(
                .animation(duration: duration, delay: delay, options: options, timingFunction: timingFunction, animations: animations)
            )
            return self
        }
        
        /// Adds an animation sequence to the animation group
        ///
        /// Adding each part in the group can by done in a chain, as this method returns `Self`
        /// - Parameters:
        ///   - addSteps: Amount of time (in seconds)  the animation should last
        ///   - delay: Amount of time (in seconds) the animation should wait to start
        ///   - options: Options to use for the animation
        ///   - timingFunction: `CAMediaTimingFunction` to use for animation
        ///   - animations: Closure in which values to animate should be changed
        /// - Returns: Returns self, enabling the use of chaining mulitple calls
        @discardableResult public func animateSteps(_ addSteps: (AnimationSequence) -> Void) -> Self {
            let sequence = AnimationSequence()
            addSteps(sequence)
            animations.append(.sequence(sequence: sequence))
            return self
        }
    }
}


extension AnimationSequence {
    
    /// Adds a group of animations, all of which will be executed add once.
    /// - Parameter addAnimations: Closure used to add animations to the provided `Group` object
    /// - Returns: Returns self, enabling the use of chaining mulitple calls
    @discardableResult public func addGroup(with addAnimations: (Group) -> Void) -> Self {
        let group = Group()
        addAnimations(group)
        steps.append(
            .group(animations: group.animations)
        )
        return self
    }
}

// MARK: - Actual animation logic
extension AnimationSequence.Step: Animatable {
    
    /// Full duration for each step type, uses longest duration of animations in a group
    public var duration: TimeInterval {
        switch self {
        case .animation(let duration, let delay, _, _, _):
            return duration + delay
        case .delay(let delay):
            return delay
        case .group(let steps):
            guard let longestDuration = steps.map({ $0.duration }).max() else {
                return 0
            }
            return longestDuration
        case .sequence(let sequence):
            return sequence.duration
        }
        
    }
    
    /// Perform the animation for this step
    ///
    /// Wraps animation steps with a `timingFunction` in a `CATransaction` commit
    /// - Parameters:
    ///   - delay: Time in seconds to wait to perform the animation
    ///   - completion: Closure to be executed when animation has finished
    fileprivate func animate(
        withDelay delay: TimeInterval,
        completion: ((Bool) -> Void)?
    ) {
        switch self {
        case .animation(let duration, let animationDelay, let options, let timingFunction, let animations):
            let createAnimations: (((Bool) -> Void)?) -> Void = { completion in
                UIView.animate(
                    withDuration: duration,
                    delay: delay + animationDelay,
                    options: options,
                    animations: animations,
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
        case .group(let steps as [Animatable]):
            let sortedSteps = Array(steps.sorted(by: { $0.duration < $1.duration }))
            guard let longestStep = sortedSteps.last else {
                // No sequences to animate, call completion
                completion?(true)
                return
            }
            sortedSteps.dropLast().forEach { step in
                step.animate(withDelay: delay, completion: nil)
            }
            // Animate the longest sequence with the completion, so the completion closure
            // is executed when all sequences _should_ be completed
            longestStep.animate(withDelay: delay, completion: completion)
        case .sequence(let sequence):
            sequence.animate(
                withDelay: delay,
                completion: completion)
        case .delay(_):
            fatalError("Delay steps should not be animated")
        }
    }
}

extension AnimationSequence: Animatable {
    
    /// Total duration of sequence
    public var duration: TimeInterval {
        steps.reduce(0, { $0 + $1.duration })
    }
    
    fileprivate func animate(withDelay delay: TimeInterval, completion: ((Bool) -> Void)?) {
        UIView.animate(remainingSteps: steps, startingDelay: delay, completion: completion)
    }
}

extension UIView: StepAnimatable {
    
    public class func animateSteps(_ addSteps: (AnimationSequence) -> Void, completion: ((Bool) -> Void)? = nil) {
        let sequence = AnimationSequence()
        
        // Call the block with the sequence object,
        // hopefully resulting in steps added to the sequence
        addSteps(sequence)
        
        // Start animating all the steps
        sequence.animate(withDelay: 0, completion: completion)
    }
    
    public static func animateGroup(_ addAnimations: (AnimationSequence.Group) -> Void, completion: ((Bool) -> Void)?) {
        animateSteps({ sequence in
            // Just add one group step with the addAnimations closure
            sequence.addGroup(with: addAnimations)
        }, completion: completion)
    }
}

fileprivate extension UIView {
    
    /// Recursive method that calls itself with less remaining steps each time
    /// - Parameters:
    ///   - steps: Array of steps that needs to be animated
    ///   - completion: Completion closure to be executed when last step has finished
    class func animate(remainingSteps steps: [AnimationSequence.Step], startingDelay: TimeInterval = 0, completion: ((Bool) -> Void)? = nil) {
        
        var cummulativeDelay: TimeInterval = startingDelay
        
        // Drop any initial steps with just a delay, but keep track of their delay
        let animatableSteps = steps.drop { step in
            if case let .delay(delay) = step {
                cummulativeDelay += delay
                return true
            }
            return false
        }
        
        guard let step = animatableSteps.first else {
            // When there‘s no more steps available, there‘s no more animations to be done
            guard let completion = completion else {
                // No completion closure to call
                return
            }

            if cummulativeDelay > 0 {
                // Wait out the remaing delay until calling completion closure
                DispatchQueue.main.asyncAfter(deadline: .now() + cummulativeDelay) {
                    completion(true)
                }
            } else {
                completion(true)
            }
            return
        }
        
        let remainingSteps = animatableSteps.dropFirst()
        
        // Actually perform animation for first step to animate
        // with the accumulated delay of possible previous delay steps
        step.animate(withDelay: cummulativeDelay) { finished in
            guard finished else {
                completion?(finished)
                return
            }
            // Recursively call this class method again with the remaining steps
            animate(remainingSteps: Array(remainingSteps), completion: completion)
        }
    }
}
