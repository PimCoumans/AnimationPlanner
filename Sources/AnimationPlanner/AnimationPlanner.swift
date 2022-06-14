import UIKit

/// This class is used to add steps to your animation sequence. When starting a sequence animation with `UIView.animateSteps(_:completion:)`, a sequence object is made available through the `addSteps` closure, From within this closure each step should be added to the sequence object.
///
/// Each method on ``AnimationSequence`` returns a reference to `Self`, enabling the use of chainging each method call.
///
/// Setting up your animation should be done with the following methods:
/// - ``delay(_:)`` adds a delay to the sequence. Delays are cumulative and are applied to the first actual animation to be performend.
/// -  ``add(duration:options:timingFunction:animations:)`` adds an animation step to the sequence, providing a specific duration and optionally the `UIView.AnimationOptions` options and a `CAMediaTimingFunction` timing function.
/// - ``addSpring(duration:delay:damping:initialVelocity:options:animations:)`` adds a spring-based animation step with the expected damping and velocity values.
/// - ``extra(_:)`` adds an ‘extra’ step to prepare state before or between steps for the next animation or perform side-effects like triggering haptic feedback.
/// - ``addGroup(with:)`` creates a ``Group`` object to which multiple animations can be added that should be performed simultaneously.
///
/// - Note: Each animation is created right before it needs to be executed, so referencing values changed in previous steps is possible.
public class AnimationSequence {
    
    /// All steps currently added to the sequence
    public internal(set) var steps: [Step] = []
    
    /// A step for each animation in the sequence. These steps are created when using the available methods on ``AnimationSequence``.
    public enum Step {
        /// A step that merely adds a delay, accumulated to be applied to the next step with actual animations.
        /// - Parameter duration: Duration of the delay in seconds
        case delay(duration: TimeInterval)
        
        /// An animation step that results in a `UIView.animate()` call with all the necessary parameters
        /// - Parameter duration: Duration of the animation
        /// - Parameter delay: Delay for the animation, only used in some specific cases
        /// - Parameter options: Animation options, when `.repeats` make sure to set a limit or any subsequent next step might not be executed
        /// - Parameter timingFunction: `CAMediaTimingFunction` to apply to animation, will wrap animation in `CATransaction`
        /// - Parameter animations: Closure in which values to animate should be changed
        case animation(
            duration: TimeInterval,
            delay: TimeInterval,
            options: UIView.AnimationOptions? = [],
            timingFunction: CAMediaTimingFunction? = nil,
            animations: () -> Void)
        
        /// An spring-based animation step that results in the appropriate `UIView.animate()` call with all the necessary parameters
        /// - Parameter duration: Duration of the animation
        /// - Parameter delay: Delay for the animation, only used in some specific cases
        /// - Parameter dampingRatio: Daming ratio for the spring animation
        /// - Parameter velocity: Relative initial velocity for the spring animation
        /// - Parameter options: Animation options, when `.repeats` make sure to set a limit or any subsequent next step might not be executed
        /// - Parameter animations: Closure in which values to animate should be changed
        case springAnimation(
            duration: TimeInterval,
            delay: TimeInterval,
            dampingRatio: CGFloat,
            velocity: CGFloat,
            options: UIView.AnimationOptions? = [],
            animations: () -> Void)
        
        /// A step where preparations or side-effects can be handled. Comparable to a 0-duration animation, without actually being
        /// animated in a `UIView` animation closure.
        case extra(delay: TimeInterval, handler: () -> Void)
        
        /// Step that contains group of animation steps, all of which should be performed simultaniously
        /// - Parameter animations: All the steps to animate at the same time
        case group(animations: [Self])
        
        /// A step holding another animation sequence, only to be used in an animation group
        /// - Parameters:
        ///   - sequence: ``AnimationSequence`` object to be added to the group
        case sequence(sequence: AnimationSequence)
    }
}

/// Extension methods that start an animation sequence, added to `UIView` by default
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

internal protocol Animatable {
    var duration: TimeInterval { get }
    func animate(withDelay delay: TimeInterval, completion: ((Bool) -> Void)?)
}

extension AnimationSequence {
    
    /// Adds an animation to the sequence with all the expected animation parameters, adding the ability to use a `CAMediaTimingFunction` timing function for the interpolation.
    ///
    /// Adding each steps can by done in a chain, as this method returns `Self`
    /// - Note: Adding a timing function will wrap the animation in a `CATransaction` commit
    /// - Parameters:
    ///   - duration: How long the animation should last
    ///   - options: Options to use for the animation
    ///   - timingFunction: `CAMediaTimingFunction` to use for animation
    ///   - animations: Closure in which values to animate should be changed
    /// - Returns: Returns `Self`, enabling the use of chaining mulitple calls
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
    
    /// Adds a spring-based animation to the animation sequence with all the expected animation parameters.
    ///
    /// Adding each step in the sequence can by done in a chain, as this method returns `Self`
    /// - Note: Timing curves aren‘t available in this method by design, the spring itself should do all the interpolating.
    /// - Parameters:
    ///   - duration: Amount of time (in seconds)  the animation should last
    ///   - delay: Amount of time (in seconds) the animation should wait to start
    ///   - dampingRatio: Ratio for damping of spring animation (between 0 and 1)
    ///   - velocity: Initial velocity of spring animation (1 being full 'distance' in one second)
    ///   - options: Options to use for the animation
    ///   - animations: Closure in which values to animate should be changed
    /// - Returns: Returns `Self`, enabling the use of chaining mulitple calls
    @discardableResult public func addSpring(
        duration: TimeInterval,
        delay: TimeInterval = 0,
        damping dampingRatio: CGFloat,
        initialVelocity velocity: CGFloat = 0,
        options: UIView.AnimationOptions = [],
        animations: @escaping () -> Void
    ) -> Self {
        steps.append(
            .springAnimation(duration: duration, delay: delay, dampingRatio: dampingRatio, velocity: velocity, animations: animations)
        )
        return self
    }
    
    /// Adds a delay to the animation sequence
    ///
    /// While this adds an actual step to the sequence, in practice the next step that actually does
    /// the animation will use this delay (or all previous delays leading up to that step).
    /// - Parameter delay: Duration of the delay
    /// - Returns: Returns `Self`, enabling the use of chaining mulitple calls
    @discardableResult public func delay(_ duration: TimeInterval) -> Self {
        steps.append(
            .delay(duration: duration)
        )
        return self
    }
}

extension AnimationSequence {
    /// Adds a step where preparations or side-effects can be handled. Comparable to a 0-duration animation, but without actually being
    /// animated in a `UIView` animation closure.
    /// - Parameter handler: Closure exectured at the specific time in the sequence
    /// - Returns: Returns `Self`, enabling the use of chaining mulitple calls
    @discardableResult public func extra(_ handler: @escaping () -> Void) -> Self {
        steps.append(.extra(delay: 0, handler: handler))
        return self
    }
}

extension AnimationSequence {
    
    /// Group of animation steps, all of which should be performed simultaniously
    public class Group {
        
        /// All animations currently added to the sequence
        public internal(set) var animations: [Step] = []
        
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
        /// - Returns: Returns `Self`, enabling the use of chaining mulitple calls
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
        
        /// Adds a spring-based animation to the animation group with all the available options.
        ///
        /// Adding each part in the group can by done in a chain, as this method returns `Self`
        /// - Parameters:
        ///   - duration: Amount of time (in seconds)  the animation should last
        ///   - delay: Amount of time (in seconds) the animation should wait to start
        ///   - dampingRatio: Ratio for damping of spring animation (between 0 and 1)
        ///   - velocity: Initial velocity of spring animation (1 being full 'distance' in one second)
        ///   - options: Options to use for the animation
        ///   - animations: Closure in which values to animate should be changed
        /// - Returns: Returns `Self`, enabling the use of chaining mulitple calls
        @discardableResult public func animateSpring(
            duration: TimeInterval,
            delay: TimeInterval = 0,
            damping dampingRatio: CGFloat,
            initialVelocity velocity: CGFloat,
            options: UIView.AnimationOptions = [],
            animations: @escaping () -> Void
        ) -> Self {
            self.animations.append(
                .springAnimation(duration: duration, delay: delay, dampingRatio: dampingRatio, velocity: velocity, animations: animations)
            )
            return self
        }
        
        /// Adds an ‘extra’ step where preparations or side-effects can be handled. Comparable to a 0-duration animation,  without actually being
        /// animated in a `UIView` animation closure.
        /// - Parameter delay: Amount of time (in seconds) the handler should wait to be executed
        /// - Parameter handler: Closure exectured at the specific time in the sequence
        /// - Returns: Returns `Self`, enabling the use of chaining mulitple calls
        @discardableResult public func extra(delay: TimeInterval = 0, handler: @escaping () -> Void) -> Self {
            animations.append(.extra(delay: delay, handler: handler))
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
        /// - Returns: Returns `Self`, enabling the use of chaining mulitple calls
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
    /// - Returns: Returns `Self`, enabling the use of chaining mulitple calls
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
        case .animation(let duration, let delay, _, _, _), .springAnimation(let duration, let delay, _, _, _, _):
            return duration + delay
        case .delay(let delay), .extra(let delay, _):
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
    func animate(
        withDelay leadingDelay: TimeInterval,
        completion: ((Bool) -> Void)?
    ) {
        switch self {
        case .animation(let duration, let delay, let options, let timingFunction, let animations):
            let createAnimations: (((Bool) -> Void)?) -> Void = { completion in
                UIView.animate(
                    withDuration: duration,
                    delay: leadingDelay + delay,
                    options: options ?? [],
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
        case .springAnimation(let duration, let delay, let dampingRatio, let velocity, let options, let animations):
            UIView.animate(
                withDuration: duration,
                delay: leadingDelay + delay,
                usingSpringWithDamping: dampingRatio,
                initialSpringVelocity: velocity,
                options: options ?? [],
                animations: animations,
                completion: completion
            )
        case .extra(let delay, let handler):
            // Perform handler with the optional delay
            let perform = {
                handler()
                completion?(true)
            }
            let peformDelay = leadingDelay + delay
            if peformDelay > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + peformDelay, execute: perform)
            } else {
                perform()
            }
        case .group(let steps as [Animatable]):
            let sortedSteps = Array(steps.sorted(by: { $0.duration < $1.duration }))
            guard let longestStep = sortedSteps.last else {
                // No sequences to animate, call completion
                completion?(true)
                return
            }
            sortedSteps.dropLast().forEach { step in
                step.animate(withDelay: leadingDelay, completion: nil)
            }
            // Animate the longest sequence with the completion, so the completion closure
            // is executed when all sequences _should_ be completed
            longestStep.animate(withDelay: leadingDelay, completion: completion)
        case .sequence(let sequence):
            sequence.animate(
                withDelay: leadingDelay,
                completion: completion)
        case .delay(_):
            fatalError("Delay steps should not be animated")
        }
    }
}

extension AnimationSequence: Animatable {
    
    /// Total duration of all steps in the sequence combined
    public var duration: TimeInterval {
        steps.reduce(0, { $0 + $1.duration })
    }
    
    internal func animate(withDelay delay: TimeInterval, completion: ((Bool) -> Void)?) {
        UIView.animate(remainingSteps: steps, startingDelay: delay, completion: completion)
    }
}

extension StepAnimatable {
    
    public static func animateSteps(_ addSteps: (AnimationSequence) -> Void, completion: ((Bool) -> Void)? = nil) {
        let sequence = AnimationSequence()
        
        // Call the block with the sequence object,
        // hopefully resulting in steps added to the sequence
        addSteps(sequence)
        
        // Start animating all the steps
        sequence.animate(withDelay: 0, completion: completion)
    }
    
    public static func animateGroup(_ addAnimations: (AnimationSequence.Group) -> Void, completion: ((Bool) -> Void)? = nil) {
        animateSteps({ sequence in
            // Just add one group step with the addAnimations closure
            sequence.addGroup(with: addAnimations)
        }, completion: completion)
    }
}

/// Applying ``StepAnimatable``  to `UIView`
extension UIView: StepAnimatable { }

extension StepAnimatable {
    
    /// Recursive method that calls itself with less remaining steps each time
    /// - Parameters:
    ///   - steps: Array of steps that needs to be animated
    ///   - completion: Completion closure to be executed when last step has finished
    static func animate(remainingSteps steps: [AnimationSequence.Step], startingDelay: TimeInterval = 0, completion: ((Bool) -> Void)? = nil) {
        
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
        let startTime = CACurrentMediaTime()
        
        // Actually perform animations for first remaining step,
        // delaying for the accumulated delay of possible previous delay steps
        step.animate(withDelay: cummulativeDelay) { finished in
            guard finished else {
                completion?(finished)
                return
            }
            
            let actualDuration = CACurrentMediaTime() - startTime
            let difference = (step.duration + cummulativeDelay) - actualDuration
            let oneFrameDifference: TimeInterval = 1/60
            
            guard difference <= 0.1 || actualDuration > oneFrameDifference else {
                // UIView animation probably wasn‘t executed because no actual animatable
                // properties were changed in animation closure. Just wait out remaining time
                // before moving over to the next step.
                let waitTime = max(0, difference - oneFrameDifference) // reduce a frame to be safe
                DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                    animate(remainingSteps: Array(remainingSteps), completion: completion)
                }
                return
            }
            // Recursively call this class method again with the remaining steps
            animate(remainingSteps: Array(remainingSteps), completion: completion)
        }
    }
}
