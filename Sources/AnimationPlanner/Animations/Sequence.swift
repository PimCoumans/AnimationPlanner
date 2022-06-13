import UIKit

public struct Sequence: AnimatesDelayed, AnimatesSimultaneously {
    public let duration: TimeInterval
    public var totalDuration: TimeInterval { delay + duration }
    
    public let delay: TimeInterval
    public let animations: [AnimatesInSequence]
    
    internal init(delay: TimeInterval, animations: [AnimatesInSequence]) {
        self.delay = delay
        self.animations = animations
        duration = animations.reduce(0, { $0 + $1.duration })
    }
    
    public init(@AnimationBuilder _ build: () -> [AnimatesInSequence]) {
        self.init(delay: 0, animations: build())
    }
}

extension Sequence: DelayModifier {
    public func delayed(_ delay: TimeInterval) -> Self {
        return Self.init(delay: delay, animations: animations)
    }
}

extension Sequence: PerformsAnimations {
    public func animate(delay: TimeInterval, completion: ((Bool) -> Void)?) {
        // FIXME: Groups don't animate yet
    }
}
