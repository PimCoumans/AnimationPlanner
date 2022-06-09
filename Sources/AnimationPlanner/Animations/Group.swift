import UIKit

public struct Group: SequenceAnimates {
    
    let animations: [GroupAnimates]
    
    public init(@AnimationPlanner.AnimationBuilder<GroupAnimates> _ build: () -> [GroupAnimates]) {
        animations = build()
    }
}

extension Group {
    public var duration: TimeInterval {
        let longestAnimation = animations.max { $0.duration < $1.duration }
        return longestAnimation?.duration ?? 0
    }
}
