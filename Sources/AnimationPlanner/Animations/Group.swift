import UIKit

public struct Group: SequenceAnimates {
    
    let animations: [GroupAnimates]
    
    public init(@AnimationBuilder<GroupAnimates> _ build: () -> [GroupAnimates]) {
        animations = build()
        let longestAnimation = animations.max { $0.totalDuration < $1.totalDuration }
    }
}

extension Group {
    public var duration: TimeInterval {
        let longestAnimation = animations.max { $0.totalDuration < $1.totalDuration }
        return longestAnimation?.duration ?? 0
    }
}
