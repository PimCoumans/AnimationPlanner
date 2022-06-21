import UIKit

/// Pauses the sequence for the given amount of seconds before performing the next animation.
public struct Wait: SequenceAnimatable {
    public let duration: TimeInterval
    
    public init(_ duration: TimeInterval) {
        self.duration = duration
    }
}
