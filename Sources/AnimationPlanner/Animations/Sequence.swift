import UIKit

/// Provides an sequence animation to a ``Group``, creating the ability to run multiple sequences in parallel.  Add each animation through the `animations` closure in the initializer.
public struct Sequence: DelayedAnimates {
    
    public var duration: TimeInterval { delay + originalDuration }
    public var originalDuration: TimeInterval { runningSequence.duration }
    
    public let delay: TimeInterval
    
    /// All animations added to the sequence
    public var animations: [AnimatesInSequence] { runningSequence.animations }
    
    let runningSequence: RunningSequence
    
    internal init(delay: TimeInterval, animations: [AnimatesInSequence]) {
        self.delay = delay
        self.runningSequence = RunningSequence(animations: animations)
    }
    
    /// Creates a new `Sequence` providing a way to perform a sequence animation from withing a group. Each animation is perform in in order, meaning each subsequent animation starts right after the previous completes.
    /// - Parameter animations: Add each animation from within this closure. Animations added to a sequence should conform to ``AnimatesInSequence``.
    public init(@AnimationBuilder animations builder: () -> [AnimatesInSequence]) {
        self.init(delay: 0, animations: builder())
    }
}

extension Sequence: PerformsAnimations {
    public func animate(delay: TimeInterval, completion: ((Bool) -> Void)?) {
        runningSequence
            .onCompletion { finished in
                completion?(finished)
            }
            .animate(delay: delay)
    }
}
