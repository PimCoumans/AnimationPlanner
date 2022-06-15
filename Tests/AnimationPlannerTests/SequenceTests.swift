import AnimationPlanner
import UIKit

class SequenceTests: AnimationPlannerTests {
    func testNoopSequenceAnimation() {
        runAnimationTest { completion, duration, _ in
            UIView.animateSteps { sequence in
                sequence.add(duration: duration) {
                    print("🤫 Do nothing")
                }
            } completion: { finished in
                completion(finished)
            }
        }
    }
    
    /// Sequence animation with one step
    func testBasicAnimation() {
        runAnimationTest { completion, duration, _ in
            UIView.animateSteps { sequence in
                sequence.add(duration: duration) {
                    self.performRandomAnimation()
                }
            } completion: { finished in
                completion(finished)
            }
        }
    }
    
    /// Uses an `extra` step for the completion handler after delaying for the set random duration
    func testExtraHandler() {
        runAnimationTest { completion, usedDuration, usedPrecision in
            UIView.animateSteps { sequence in
                sequence
                    .delay(usedDuration)
                    .extra {
                        completion(true)
                    }
            }
        }
    }
    
    func testBasicSpringAnimation() {
        runAnimationTest { completion, usedDuration, usedPrecision in
            UIView.animateSteps { sequence in
                sequence.addSpring(duration: usedDuration, damping: 0.86, initialVelocity: 0.2) {
                    self.performRandomAnimation()
                }
            } completion: { finished in
                completion(finished)
            }
        }
    }
    
    /// Performs a sequence animation with two steps using custom `CAMediaTimingFunction`s
    func testTimingFunctionAnimation() {
        let singleDuration: TimeInterval = randomDuration
        let totalDuration = singleDuration * 2
        
        runAnimationTest(duration: totalDuration) { completion, _, _ in
            UIView.animateSteps { sequence in
                sequence.add(duration: singleDuration, timingFunction: .quadOut) {
                    self.performRandomAnimation()
                }
                .add(duration: singleDuration, timingFunction: .quadIn) {
                    self.performRandomAnimation()
                }
            } completion: { finished in
                completion(finished)
            }
        }
    }
    
    /// Creates multiple steps each of varying durations
    func testMultipleSteps() {
        let numberOfSteps: Int = 4
        let durations = randomDurations(amount: numberOfSteps)
        let totalDuration = durations.reduce(0, +)
        let precision = durationPrecision * TimeInterval(numberOfSteps)
        
        runAnimationTest(duration: totalDuration, precision: precision) { completion, _, _ in
            UIView.animateSteps { sequence in
                for duration in durations {
                    sequence.add(duration: duration) {
                        self.performRandomAnimation()
                    }
                }
            } completion: { finished in
                completion(finished)
            }
        }
    }
    
    func testStepsWithDelay() {
        let numberOfSteps: Int = 4
        let animations = randomDelayedAnimations(amount: numberOfSteps)
        
        let totalDuration: TimeInterval = animations.reduce(0, { $0 + $1.totalDuration })
        let precision = durationPrecision * TimeInterval(numberOfSteps)
        
        runAnimationTest(duration: totalDuration, precision: precision) { completion, _, _ in
            UIView.animateSteps { sequence in
                animations.forEach { animation in
                    sequence.add(duration: animation.duration) {
                        self.performRandomAnimation()
                    }
                    .delay(animation.delay)
                }
            } completion: { finished in
                completion(finished)
            }
        }
    }
}
