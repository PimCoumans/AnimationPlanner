import UIKit

/// (Deprecated, uses intermediate classes instead of ``AnimationBuilder``)
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
    public internal(set) var steps: [SequenceAnimatable] = []
}

/// Extension methods that start an animation sequence, added to `UIView` by default
public protocol StepAnimatable {
    
    /// Start a sequence where you add each step in the `addSteps` closure. Use the provided `Sequence` object
    /// to add each step which should either be an actual animation or a delay.
    /// The `completion` closure is executed when the last animation has finished.
    /// - Parameters:
    ///   - addSteps: Closure used to add steps to the provided `Sequence` object
    ///   - completion: Executed when the last animation has finished.
    @available(*, deprecated, message: "Use `AnimationPlanner.plan` instead")
    static func animateSteps(_ addSteps: (AnimationSequence) -> Void, completion: ((Bool) -> Void)?)

    /// Start a group animation where you add each animation is performed concurrently. Use the provided `Group` object
    /// to add each animation.
    /// The `completion` closure is executed when the last animation has finished.
    /// - Parameters:
    ///   - addAnimations: Closure used to add animations to the provided `Group` object
    ///   - completion: Executed when the longest animation has finished.
    @available(*, deprecated, message: "Use `AnimationPlanner.group` instead")
    static func animateGroup(_ addAnimations: (AnimationSequence.SequenceGroup) -> Void, completion: ((Bool) -> Void)?)
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
            Animate(duration: duration, timingFunction: timingFunction, changes: animations)
                .options(options)
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
        let spring = AnimateSpring(duration: duration, dampingRatio: dampingRatio, initialVelocity: velocity, changes: animations)
            .options(options)
        
        if delay > 0 {
            fatalError("Delay here is not supported")
        } else {
            steps.append(spring)
        }
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
            Wait(duration)
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
        steps.append(
            Extra(perform: handler)
        )
        return self
    }
}

extension AnimationSequence {
    
    /// Group of animation steps, all of which should be performed simultaneously
    public class SequenceGroup {
        
        /// All animations currently added to the sequence
        public internal(set) var animations: [GroupAnimatable] = []
        
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
            var delayed = AnimateDelayed(delay: delay, duration: duration, changes: animations)
                .options(options)
            if let timingFunction = timingFunction {
                delayed = delayed.timingFunction(timingFunction)
            }
            self.animations.append(
                delayed
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
                AnimateSpring(duration: duration, dampingRatio: dampingRatio, initialVelocity: velocity, changes: animations)
                    .delayed(delay)
                    .options(options)
            )
            return self
        }
        
        /// Adds an ‘extra’ step where preparations or side-effects can be handled. Comparable to a 0-duration animation,  without actually being
        /// animated in a `UIView` animation closure.
        /// - Parameter delay: Amount of time (in seconds) the handler should wait to be executed
        /// - Parameter handler: Closure exectured at the specific time in the sequence
        /// - Returns: Returns `Self`, enabling the use of chaining mulitple calls
        @discardableResult public func extra(delay: TimeInterval = 0, handler: @escaping () -> Void) -> Self {
            animations.append(
                Extra(perform: handler)
                    .delayed(delay)
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
        /// - Returns: Returns `Self`, enabling the use of chaining mulitple calls
        @discardableResult public func animateSteps(_ addSteps: (AnimationSequence) -> Void) -> Self {
            let sequence = AnimationSequence()
            addSteps(sequence)
            animations.append (
                Sequence(delay: 0, animations: sequence.steps)
            )
            return self
        }
    }
}


extension AnimationSequence {
    
    /// Adds a group of animations, all of which will be executed add once.
    /// - Parameter addAnimations: Closure used to add animations to the provided `Group` object
    /// - Returns: Returns `Self`, enabling the use of chaining mulitple calls
    @discardableResult public func addGroup(with addAnimations: (SequenceGroup) -> Void) -> Self {
        let group = SequenceGroup()
        addAnimations(group)
        steps.append(
            Group(animations: group.animations)
        )
        return self
    }
}

extension StepAnimatable {
    
    public static func animateSteps(_ addSteps: (AnimationSequence) -> Void, completion: ((Bool) -> Void)? = nil) {
        let sequence = AnimationSequence()
        
        // Call the block with the sequence object,
        // hopefully resulting in steps added to the sequence
        addSteps(sequence)
        
        let runningSequence = RunningSequence(animations: sequence.steps)
        runningSequence.onComplete { finished in
            completion?(finished)
        }
        runningSequence.animate()
    }
    
    public static func animateGroup(_ addAnimations: (AnimationSequence.SequenceGroup) -> Void, completion: ((Bool) -> Void)? = nil) {
        
        let group = AnimationSequence.SequenceGroup()
        addAnimations(group)
        
        let runningSequence = RunningSequence(animations: [Group(animations: group.animations)])
        runningSequence.onComplete { finished in
            completion?(finished)
        }
        runningSequence.animate()
    }
}

/// Applying ``StepAnimatable``  to `UIView`
@available(*, deprecated, message: "Use `AnimationPlanner.plan` instead")
extension UIView: StepAnimatable { }
