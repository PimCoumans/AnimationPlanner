import UIKit

/// Contain multiple animations that should be performed at the same time. Add each animation through the `animations` closure in the initializer.
public struct Group: SequenceAnimatable {
    
    /// Duration of a simultaneous group is the longest `totalAnimation` (which should include its delay)
    public var duration: TimeInterval {
        return longestAnimation?.duration ?? 0
    }
    
    /// All animations added to the group
    public let animations: [GroupAnimatable]
    
    let longestAnimation: GroupAnimatable?
    
    internal init(animations: [GroupAnimatable]) {
        self.animations = animations
        self.longestAnimation = self.animations.max { $0.duration < $1.duration }
    }
    
    /// Creates a new `Group` providing a way to perform multiple animations simultaneously, meaning all animations run at the same time.
    /// - Parameter animations: Add each animation from within this closure. Animations added to a group should conform to ``GroupAnimatable``.
    public init(@AnimationBuilder animations builder: () -> [GroupAnimatable]) {
        self.init(animations: builder())
    }
}

extension Group: PerformsAnimations {
    
    public func animate(delay: TimeInterval, completion: ((Bool) -> Void)?) -> PerformsAnimations {
        var sortedAnimations = animations
            .sorted { $0.duration < $1.duration }
            .compactMap { $0 as? PerformsAnimations }
        
        guard !sortedAnimations.isEmpty else {
            completion?(true)
            return self
        }
        
        let longestAnimation = sortedAnimations.removeLast()
        var animations = sortedAnimations.compactMap { animation in
            animation.animate(delay: delay, completion: nil) as? GroupAnimatable
        }
        if let animation = longestAnimation.animate(delay: delay, completion: completion) as? GroupAnimatable {
            animations.append(animation)
        }
        return Group(animations: animations)
    }
    
    public func stop() {
        animations
            .compactMap { $0 as? PerformsAnimations }
            .forEach { $0.stop() }
    }
}
