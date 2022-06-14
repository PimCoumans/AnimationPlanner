import UIKit

/// Provides an sequence animation to a ``Group``, creating the ability to run multiple sequences in parallel.  Add each animation through the `animations` closure in the initializer.
public struct Sequence: AnimatesSimultaneously {
    public let duration: TimeInterval
    public var totalDuration: TimeInterval { delay + duration }
    
    public let delay: TimeInterval
    public let animations: [AnimatesInSequence]
    
    internal init(delay: TimeInterval, animations: [AnimatesInSequence]) {
        self.delay = delay
        self.animations = animations
        duration = animations.reduce(0, { $0 + $1.duration })
    }
    
    /// Creates a new `Sequence` providing a way to perform a sequence animation from withing a group. Each animation is perform in in order, meaning each subsequent animation starts right after the previous completes.
    /// - Parameter animations: Add each animation from within this closure. Animations added to a sequence should conform to ``AnimatesInSequence``.
    public init(@AnimationBuilder animations builder: () -> [AnimatesInSequence]) {
        self.init(delay: 0, animations: builder())
    }
}

extension Sequence: PerformsAnimations {
    public func animate(delay: TimeInterval, completion: ((Bool) -> Void)?) {
        // FIXME: Sequences don't animate yet, should be implemeted in Phase 2
        fatalError("Sequence animation not yet implemented")
    }
}
