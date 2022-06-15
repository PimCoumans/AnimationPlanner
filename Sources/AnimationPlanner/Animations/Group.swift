import UIKit

/// Contain multiple animations that should be performed at the same time. Add each animation through the `animations` closure in the initializer.
public struct Group: AnimatesInSequence {
    
    /// Duration of a simultaneous group is the longest `totalAnimation` (which should include its delay)
    public var duration: TimeInterval {
        return longestAnimation?.totalDuration ?? 0
    }
    
    /// All animations added to the group
    public let animations: [AnimatesSimultaneously]
    
    let longestAnimation: AnimatesSimultaneously?
    
    internal init(animations: [AnimatesSimultaneously]) {
        self.animations = animations
        self.longestAnimation = self.animations.max { $0.totalDuration < $1.totalDuration }
    }
    
    /// Creates a new `Group` providing a way to perform multiple animations simultaneously, meaning all animations run at the same time.
    /// - Parameter animations: Add each animation from within this closure. Animations added to a group should conform to ``AnimatesSimultaneously``.
    public init(@AnimationBuilder animations builder: () -> [AnimatesSimultaneously]) {
        self.init(animations: builder())
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
