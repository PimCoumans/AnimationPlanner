import AnimationPlanner
import UIKit

class SequenceTests: AnimationPlannerTests {
    
    /// Performs no actual animation, but should not finish earlier than duration
    func testNoopSequenceAnimation() {
        
        runAnimationBuilderTest { duration, _ in
            AnimationPlanner.plan {
                Animate(duration: duration)
            }
        }
        
    }
    
    /// Sequence animation with one step
    func testBasicAnimation() {
        runAnimationBuilderTest { duration, _ in
            
            AnimationPlanner.plan {
                Animate(duration: duration) {
                    self.performRandomAnimation()
                }
            }
            
        }
    }
    
    /// Uses an `extra` step for the completion handler after delaying for the set random duration
    func testExtraHandler() {
        runAnimationTest { completion, usedDuration, _ in
            
            AnimationPlanner.plan {
                Wait(usedDuration)
                Extra {
                    completion(true)
                }
            }
        }
    }
    
    func testBasicSpringAnimation() {
        runAnimationBuilderTest { usedDuration, usedPrecision in
            
            AnimationPlanner.plan {
                AnimateSpring(duration: usedDuration, dampingRatio: 0.86, initialVelocity: 0.2) {
                    self.performRandomAnimation()
                }
            }
            
        }
    }
    
    /// Performs a sequence animation with two steps using custom `CAMediaTimingFunction`s
    func testTimingFunctionAnimation() {
        let singleDuration: TimeInterval = randomDuration
        let totalDuration = singleDuration * 2
        
        runAnimationBuilderTest(duration: totalDuration) { _, _ in
            
            AnimationPlanner.plan {
                Animate(duration: singleDuration, timingFunction: .quadOut) {
                    self.performRandomAnimation()
                }
                Animate(duration: singleDuration) {
                    self.performRandomAnimation()
                }.timingFunction(.quadIn)
            }
            
        }
    }
    
    /// Creates multiple steps each of varying durations
    func testMultipleSteps() {
        let numberOfSteps: Int = 4
        let durations = randomDurations(amount: numberOfSteps)
        let totalDuration = durations.reduce(0, +)
        let precision = durationPrecision * TimeInterval(numberOfSteps)
        
        runAnimationBuilderTest(duration: totalDuration, precision: precision) { _, _ in
            
            AnimationPlanner.plan {
                for duration in durations {
                    Animate(duration: duration) {
                        self.performRandomAnimation()
                    }
                }
            }
            
        }
    }
    
    func testStepsWithDelay() {
        let numberOfSteps: Int = 4
        let animations = randomDelayedAnimations(amount: numberOfSteps)
        
        let totalDuration: TimeInterval = animations.reduce(0, { $0 + $1.totalDuration })
        let precision = durationPrecision * TimeInterval(numberOfSteps)
        
        runAnimationBuilderTest(duration: totalDuration, precision: precision) { _, _ in
            
            AnimationPlanner.plan {
                animations.mapAnimations { animation in
                    Animate(duration: animation.duration) {
                        self.performRandomAnimation()
                    }
                    Wait(animation.delay)
                }
            }
            
        }
    }
    
    func testSequenceCountedLoop() {
        let duration: TimeInterval = 0.5
        let numberOfLoops: Int = 4
        let totalDuration = duration * TimeInterval(numberOfLoops)
        let precision = durationPrecision * TimeInterval(numberOfLoops)
        runAnimationBuilderTest(duration: totalDuration, precision: precision) { _, _ in
            
            AnimationPlanner.plan {
                Loop(for: numberOfLoops) { index in
                    Animate(duration: duration / 2) {
                        self.performRandomAnimation()
                    }
                    Animate(duration: duration / 2) {
                        self.performRandomAnimation()
                    }
                }
            }
            
        }
    }
    
    func testSequenceElementLoop() {
        let numberOfLoops: Int = 4
        let durations = randomDurations(amount: numberOfLoops)
        let totalDuration: TimeInterval = durations.reduce(0, +)
        runAnimationBuilderTest(duration: totalDuration) { _, _ in
            
            AnimationPlanner.plan {
                Loop.through(durations) { duration in
                    Animate(duration: duration) {
                        self.performRandomAnimation()
                    }
                }
            }
            
        }
    }
    
    func testSequenceForLoop() {
        let numberOfLoops: Int = 4
        let durations = randomDurations(amount: numberOfLoops)
        let totalDuration: TimeInterval = durations.reduce(0, +)
        runAnimationBuilderTest(duration: totalDuration) { _, _ in
            
            AnimationPlanner.plan {
                for duration in durations {
                    Animate(duration: duration) {
                        self.performRandomAnimation()
                    }
                }
            }
            
        }
    }
    
    func testGroupCountedLoop() {
        let numberOfLoops: Int = 4
        let animations = randomDelayedAnimations(amount: numberOfLoops)
        let totalDuration: TimeInterval = animations.max { $0.totalDuration < $1.totalDuration }?.totalDuration ?? 0
        
        runAnimationBuilderTest(duration: totalDuration) { _, _ in
            
            AnimationPlanner.group {
                Loop(for: numberOfLoops) { index in
                    Animate(duration: animations[index].duration) {
                        self.performRandomAnimation()
                    }.delayed(animations[index].delay)
                }
            }
            
        }
    }
    
    func testGroupElementLoop() {
        let numberOfLoops: Int = 4
        let animations = randomDelayedAnimations(amount: numberOfLoops)
        let totalDuration: TimeInterval = animations.max { $0.totalDuration < $1.totalDuration }?.totalDuration ?? 0
        
        runAnimationBuilderTest(duration: totalDuration) { _, _ in
            
            AnimationPlanner.group {
                Loop.through(animations) { animation in
                    Animate(duration: animation.duration) {
                        self.performRandomAnimation()
                    }.delayed(animation.delay)
                }
            }
            
        }
    }
    
    func testGroupForLoop() {
        let numberOfLoops: Int = 4
        let animations = randomDelayedAnimations(amount: numberOfLoops)
        let totalDuration: TimeInterval = animations.max { $0.totalDuration < $1.totalDuration }?.totalDuration ?? 0
        
        runAnimationBuilderTest(duration: totalDuration) { _, _ in
            
            AnimationPlanner.group {
                for animation in animations {
                    Animate(duration: animation.duration) {
                        self.performRandomAnimation()
                    }.delayed(animation.delay)
                }
            }
            
        }
    }
}
