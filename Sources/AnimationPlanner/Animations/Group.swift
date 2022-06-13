import UIKit

public struct Group: AnimatesInSequence {
    
    /// Duration of a simultaneous group is the longest `totalAnimation` (which should include its delay)
    public var duration: TimeInterval {
        let longestAnimation = animations.max { $0.totalDuration < $1.totalDuration }
        return longestAnimation?.totalDuration ?? 0
    }
    
    public let animations: [AnimatesSimultaneously]
    
    public init(@AnimationBuilder _ build: () -> [AnimatesSimultaneously]) {
        animations = build()
    }
}
