import UIKit

public struct Group: AnimatesInSequence {
    
    /// Duration of a simultaneous group is the longest `totalAnimation` (which should include its delay)
    public var duration: TimeInterval {
        return longestAnimation?.totalDuration ?? 0
    }
    
    public let animations: [AnimatesSimultaneously]
    
    var longestAnimation: AnimatesSimultaneously? {
        return animations.max { $0.totalDuration < $1.totalDuration }
    }
    
    public init(@AnimationBuilder _ build: () -> [AnimatesSimultaneously]) {
        animations = build()
    }
}

extension Group: PerformsAnimations {
    public func animate(delay: TimeInterval, completion: ((Bool) -> Void)?) {
        
        var sortedAnimations = animations
            .sorted { $0.totalDuration < $1.totalDuration }
            .compactMap { $0 as? PerformsAnimations }
        
        guard !sortedAnimations.isEmpty else {
            completion?(true)
            return
        }
        
        let longestAnimation = sortedAnimations.removeFirst()
        
        sortedAnimations.forEach { animation in
            animation.animate(delay: delay, completion: nil)
        }
        longestAnimation.animate(delay: delay, completion: completion)
    }
}
