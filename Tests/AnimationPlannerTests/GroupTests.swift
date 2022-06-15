import AnimationPlanner
import UIKit

class GroupTests: AnimationPlannerTests {
    /// Adds one group with a specific number of animations  which all should be performed simultaneously
    func testGroup() {
        let numberOfSteps: Int = 8
        let durations = randomDurations(amount: numberOfSteps)
        let longestDuration = durations.max()!
        
        runAnimationTest(duration: longestDuration) { completion, _, _ in
            UIView.animateSteps { sequence in
                sequence.addGroup { group in
                    for duration in durations {
                        group.animate(duration: duration) {
                            self.performRandomAnimationOnNewView()
                        }
                    }
                }
            } completion: { finished in
                completion(finished)
            }
        }
    }
    
    /// Adds one group with a specific number of animations  which all should be performed simultaneously
    func testGroupWithDelays() {
        let numberOfSteps: Int = 4
        let animations = randomDelayedAnimations(amount: numberOfSteps)
        
        let totalDuration: TimeInterval = animations.max { $0.totalDuration < $1.totalDuration }?.totalDuration ?? 0
        
        runAnimationTest(duration: totalDuration) { completion, _, _ in
            UIView.animateSteps { sequence in
                sequence.addGroup { group in
                    animations.forEach { animation in
                        group.animate(duration: animation.duration, delay: animation.delay) {
                            self.performRandomAnimationOnNewView()
                        }
                    }
                }
            } completion: { finished in
                completion(finished)
            }
        }
    }
    
    /// Uses an `extra` step in a group for the completion handler with a delay for the set random duration
    func testExtraGroupHandler() {
        runAnimationTest { completion, usedDuration, usedPrecision in
            UIView.animateGroup { group in
                group
                    .extra(delay: usedDuration) {
                        completion(true)
                    }
            }
        }
    }
    
    /// Adds one group with a specific number of animations  which all should be performed simultaneously,
    /// but using a the simplified `UIView.animateGroup` method
    func testSimpleGroup() {
        let numberOfSteps: Int = 8
        let durations = randomDurations(amount: numberOfSteps)
        let longestDuration = durations.max()!
        
        runAnimationTest(duration: longestDuration) { completion, _, _ in
            UIView.animateGroup { group in
                for duration in durations {
                    group.animate(duration: duration) {
                        self.performRandomAnimationOnNewView()
                    }
                }
            } completion: { finished in
                completion(finished)
            }
        }
    }
    
}
