import AnimationPlanner
import Foundation
import UIKit
import XCTest

class BuilderTests: AnimationPlannerTests {
    
    /*
     During phase 1 of adding result builders to AnimationPlanner, all animations created with result builders are
     performed by the old style `UIView.animateSteps` logic. Therefore result builder tests should not be as extensive
     as the old-style tests.
     */
    
    func testContainedAnimations() {
        let animate = Animate(duration: 1)
        let spring = animate.spring(damping: 2)
        let delay = spring.delayed(3)
        
        let options: UIView.AnimationOptions = .allowAnimatedContent
        let editedDelay = delay.options(options)
        let containedAnimation = editedDelay.animation.animation
        let springed = editedDelay.spring(damping: 4)
        
        XCTAssertEqual(editedDelay.options, containedAnimation.options)
        XCTAssertEqual(editedDelay.dampingRatio, spring.dampingRatio)
        XCTAssertNotEqual(springed.dampingRatio, spring.dampingRatio)
        XCTAssertEqual(springed.delay, delay.delay)
    }
    
    func testBuilder() {
        let totalDuration: TimeInterval = 1
        let numberOfSteps: TimeInterval = 3
        let duration = totalDuration / numberOfSteps
        
        runAnimationTest(duration: totalDuration) { completion, _, _ in
    
            AnimationPlanner.plan {
                Animate(duration: duration) {
                    self.performRandomAnimation()
                }
                Wait(duration)
                Animate(duration: duration) {
                    self.performRandomAnimation()
                }
                .spring(damping: 0.8)
            } completion: { finished in
                completion(finished)
            }
        }
    }
    
    func testBuilderModifiers() {
        let totalDuration: TimeInterval = 1
        let numberOfSteps: TimeInterval = 3
        let duration = totalDuration / numberOfSteps
        
        runAnimationTest(duration: totalDuration) { completion, _, _ in
            
            AnimationPlanner.plan {
                Animate(duration: duration)
                    .changes {
                        self.performRandomAnimation()
                    }
                    .spring(damping: 0.8)
                Wait(duration)
                Animate(duration: duration) {
                    self.performRandomAnimation()
                }
                .options(.allowAnimatedContent)
            } completion: { finished in
                completion(finished)
            }
        }
    }
    
    func testBuilderContainerModifiers() {
        let totalDuration: TimeInterval = 1
        let numberOfSteps: TimeInterval = 1
        let duration = totalDuration / numberOfSteps
        
        runAnimationTest(duration: totalDuration) { completion, _, _ in
            
            AnimationPlanner.plan {
                Animate(duration: duration) {
                    self.performRandomAnimation()
                }
                .spring(damping: 0.82)
                .options(.allowUserInteraction)
            } completion: { finished in
                completion(finished)
            }
            
        }
    }
    
    func testBuilderGroup() {
        let totalDuration: TimeInterval = 5
        let numberOfSteps: TimeInterval = 4
        let duration = totalDuration / numberOfSteps
        let delay: TimeInterval = 1
        
        runAnimationTest(duration: totalDuration + delay) { completion, _, _ in
            
            AnimationPlanner.plan {
                Animate(duration: duration) {
                    self.performRandomAnimation()
                }
                Wait(duration)
                Group {
                    Animate(duration: duration, changes: {
                        self.performRandomAnimation()
                    })
                    .spring(damping: 0.82)
                    .delayed(delay / 2)
                    
                    Animate(duration: duration) {
                        self.performRandomAnimation()
                    }
                    
                    Animate(duration: duration, changes: {
                        self.performRandomAnimation()
                    })
                    .delayed(delay)
                    .spring(damping: 0.82)
                }
                Animate(duration: duration) {
                    self.performRandomAnimation()
                }
            } completion: { finished in
                completion(finished)
            }
            
        }
    }
    
    func testDelayedSpring() {
        let duration: TimeInterval = 0.5
        let delay: TimeInterval = 0.25
        let totalDuration = delay + duration
        runAnimationTest(duration: totalDuration) { completion, _, _ in
            
            AnimationPlanner.group {
                Animate(duration: duration) {
                    self.performRandomAnimation()
                }
                .spring(damping: 0.82)
                .delayed(delay)
            } completion: { finised in
                completion(finised)
            }
            
        }
    }
    
    func testSpringedDelay() {
        let duration: TimeInterval = 0.5
        let delay: TimeInterval = 0.25
        let totalDuration = delay + duration
        runAnimationTest(duration: totalDuration) { completion, _, _ in
            
            AnimationPlanner.group {
                Animate(duration: duration) {
                    self.performRandomAnimation()
                }
                .delayed(delay)
                .spring(damping: 0.82)
            } completion: { finished in
                completion(finished)
            }
            
        }
    }
    
    func testSequenceCountedLoop() {
        let duration: TimeInterval = 0.5
        let numberOfLoops: Int = 4
        let totalDuration = duration * TimeInterval(numberOfLoops)
        runAnimationTest(duration: totalDuration) { completion, _, _ in
            
            AnimationPlanner.plan {
                Loop(for: numberOfLoops) { index in
                    Animate(duration: duration / 2) {
                        self.performRandomAnimation()
                    }
                    Animate(duration: duration / 2) {
                        self.performRandomAnimation()
                    }
                }
            } completion: { finished in
                completion(finished)
            }
            
        }
    }
    
    func testSequenceElementLoop() {
        let numberOfLoops: Int = 4
        let durations = randomDurations(amount: numberOfLoops)
        let totalDuration: TimeInterval = durations.reduce(0, +)
        runAnimationTest(duration: totalDuration) { completion, _, _ in
            
            AnimationPlanner.plan {
                Loop.through(durations) { duration in
                    Animate(duration: duration) {
                        self.performRandomAnimation()
                    }
                }
            } completion: { finished in
                completion(finished)
            }
            
        }
    }
    
    func testSequenceForLoop() {
        let numberOfLoops: Int = 4
        let durations = randomDurations(amount: numberOfLoops)
        let totalDuration: TimeInterval = durations.reduce(0, +)
        runAnimationTest(duration: totalDuration) { completion, _, _ in
            
            AnimationPlanner.plan {
                for duration in durations {
                    Animate(duration: duration) {
                        self.performRandomAnimation()
                    }
                }
            } completion: { finished in
                completion(finished)
            }
            
        }
    }
    
    func testGroupCountedLoop() {
        let numberOfLoops: Int = 4
        let animations = randomDelayedAnimations(amount: numberOfLoops)
        let totalDuration: TimeInterval = animations.max { $0.totalDuration < $1.totalDuration }?.totalDuration ?? 0
        
        runAnimationTest(duration: totalDuration) { completion, _, _ in
            
            AnimationPlanner.group {
                Loop(for: numberOfLoops) { index in
                    Animate(duration: animations[index].duration) {
                        self.performRandomAnimation()
                    }.delayed(animations[index].delay)
                }
            } completion: { finished in
                completion(finished)
            }
            
        }
    }
    
    func testGroupElementLoop() {
        let numberOfLoops: Int = 4
        let animations = randomDelayedAnimations(amount: numberOfLoops)
        let totalDuration: TimeInterval = animations.max { $0.totalDuration < $1.totalDuration }?.totalDuration ?? 0
        
        runAnimationTest(duration: totalDuration) { completion, _, _ in
            
            AnimationPlanner.group {
                Loop.through(animations) { animation in
                    Animate(duration: animation.duration) {
                        self.performRandomAnimation()
                    }.delayed(animation.delay)
                }
            } completion: { finished in
                completion(finished)
            }
            
        }
    }
    
    func testGroupForLoop() {
        let numberOfLoops: Int = 4
        let animations = randomDelayedAnimations(amount: numberOfLoops)
        let totalDuration: TimeInterval = animations.max { $0.totalDuration < $1.totalDuration }?.totalDuration ?? 0
        
        runAnimationTest(duration: totalDuration) { completion, _, _ in
            
            AnimationPlanner.group {
                for animation in animations {
                    Animate(duration: animation.duration) {
                        self.performRandomAnimation()
                    }.delayed(animation.delay)
                }
            } completion: { finished in
                completion(finished)
            }
            
        }
    }
    
    func testGroupSequence() {
        let numberOfLoops: Int = 4
        let animations = randomDelayedAnimations(amount: numberOfLoops)
        let totalDuration: TimeInterval = animations.max { $0.totalDuration < $1.totalDuration }?.totalDuration ?? 0
        
        runAnimationTest(duration: totalDuration) { completion, usedDuration, usedPrecision in
            AnimationPlanner.group {
                for animation in animations {
                    Sequence {
                        Wait(animation.delay)
                        Animate(duration: animation.duration) {
                            self.performRandomAnimation()
                        }
                    }
                }
            } completion: { finished in
                completion(finished)
            }
        }
    }
}
