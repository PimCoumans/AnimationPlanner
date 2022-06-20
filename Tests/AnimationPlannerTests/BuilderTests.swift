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
        let animation = Animate(duration: 1) {
            self.performRandomAnimation()
        }
        let spring = animation.spring(damping: 2)
        
        let simplerSpring = AnimateSpring(duration: 1, dampingRatio: 2)
        XCTAssertEqual(spring.dampingRatio, simplerSpring.dampingRatio)
        XCTAssertEqual(spring.duration, simplerSpring.duration)
        
        let delay = spring.delayed(3)
        XCTAssertEqual(delay.duration, spring.duration + delay.delay)
        
        let options: UIView.AnimationOptions = .allowAnimatedContent
        let editedDelay = delay.options(options)
        let containedAnimation = editedDelay.animation.animation
        let springed = editedDelay.spring(damping: 4)
        
        XCTAssertEqual(editedDelay.options, containedAnimation.options)
        XCTAssertEqual(editedDelay.dampingRatio, spring.dampingRatio)
        XCTAssertNotEqual(springed.dampingRatio, spring.dampingRatio)
        XCTAssertEqual(springed.delay, delay.delay)
        
        let ridiculousAnimation = Animate(duration: 1)
            .delayed(2)
            .spring(damping: 3)
            .delayed(4)
            .spring(damping: 5)
            .delayed(6)
            .spring(damping: 7)
        XCTAssertEqual(ridiculousAnimation.delay, 6)
        XCTAssertEqual(ridiculousAnimation.duration, 1 + 6)
        XCTAssertEqual(ridiculousAnimation.delayed(6).delay, 6)
        XCTAssertEqual(ridiculousAnimation.delayed(6).duration, 1 + 6)
        XCTAssertEqual(ridiculousAnimation.dampingRatio, 7)
    }
    
    func testGroupDuration() {
        let group = Group {
            Animate(duration: 1)
            Animate(duration: 1)
                .spring(damping: 0.5)
                .delayed(0.5)
            Animate(duration: 1)
                .delayed(1)
                .spring(damping: 0.5)
        }
        XCTAssert(group.duration == 1 + 1)
    }
    
    func testSequenceDuration() {
        let waitStartingSequence = Sequence {
            Wait(1)
            Animate(duration: 1)
        }
        let waitEndingSequence = Sequence {
            Animate(duration: 1)
            Wait(1)
        }
        XCTAssertEqual(waitStartingSequence.duration, waitEndingSequence.duration)
    }
    
    func testGroupedSequenceDuration() {
        let animations = randomDelayedAnimations(amount: 2)
        let longestAnimation = animations.max { $0.totalDuration < $1.totalDuration}!
        let precision = durationPrecision * TimeInterval(animations.count)
        
        let waitStartingGroup = Group {
            for animation in animations {
                Sequence {
                    Wait(animation.delay)
                    Animate(duration: animation.duration)
                }
            }
        }
        
        let waitEndingGroup = Group {
            for animation in animations {
                Sequence {
                    Animate(duration: animation.duration)
                    Wait(animation.delay)
                }
            }
        }
        XCTAssertEqual(waitStartingGroup.duration, longestAnimation.totalDuration)
        XCTAssertEqual(waitStartingGroup.duration, waitEndingGroup.duration)
        
        runAnimationTest(duration: longestAnimation.totalDuration, precision: precision) { completion, _, _ in
            AnimationPlanner.plan {
                waitStartingGroup
            }.onComplete { finished in
                completion(finished)
            }
        }
        
        runAnimationTest(duration: longestAnimation.totalDuration, precision: precision) { completion, _, _ in
            AnimationPlanner.plan {
                waitStartingGroup
            }.onComplete { finished in
                completion(finished)
            }
        }
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
            }.onComplete { finished in
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
            }.onComplete { finished in
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
            }.onComplete { finished in
                completion(finished)
            }
            
        }
    }
    
    func testGroup() {
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
            }.onComplete { finished in
                completion(finished)
            }
            
        }
    }
    
    func testMultipleGroups() {
        let numberOfGroups = 2
        let numberOfSteps = 2
        let groups = (0..<numberOfGroups).map { groupIndex in
            self.randomDurations(amount: numberOfSteps)
        }
        let groupDurations = groups.compactMap { $0.max() }
        let totalDuration: TimeInterval = groupDurations.reduce(0, +)
        
        runAnimationTest(duration: totalDuration) { completion, _, _ in
            
            AnimationPlanner.plan {
                for group in groups {
                    Group {
                        let view = self.newView()
                        for duration in group {
                            Animate(duration: duration) {
                                self.performRandomAnimation(on: view)
                            }
                        }
                    }
                }
            }.onComplete { finished in
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
            }.onComplete { finished in
                completion(finished)
            }
            
        }
    }
    
    func testSpringedDelay() {
        let duration: TimeInterval = 0.5
        let delay: TimeInterval = 0.25
        let totalDuration = delay + duration
        
        let animation = Animate(duration: duration) {
            self.performRandomAnimation()
        }
        .delayed(delay)
        .spring(damping: 0.82)
        
        XCTAssertEqual(animation.duration, totalDuration)
        
        runAnimationTest(duration: totalDuration) { completion, _, _ in
            
            AnimationPlanner.group {
                Animate(duration: duration) {
                    self.performRandomAnimation()
                }
                .delayed(delay)
                .spring(damping: 0.82)
            }.onComplete { finished in
                completion(finished)
            }
            
        }
    }
    
    func testSequenceCountedLoop() {
        let duration: TimeInterval = 0.5
        let numberOfLoops: Int = 4
        let totalDuration = duration * TimeInterval(numberOfLoops)
        let precision = durationPrecision * TimeInterval(numberOfLoops)
        runAnimationTest(duration: totalDuration, precision: precision) { completion, _, _ in
            
            AnimationPlanner.plan {
                Loop(for: numberOfLoops) { index in
                    Animate(duration: duration / 2) {
                        self.performRandomAnimation()
                    }
                    Animate(duration: duration / 2) {
                        self.performRandomAnimation()
                    }
                }
            }.onComplete { finished in
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
            }.onComplete { finished in
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
            }.onComplete { finished in
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
            }.onComplete { finished in
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
            }.onComplete { finished in
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
            }.onComplete { finished in
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
            }.onComplete { finished in
                completion(finished)
            }
        }
    }
    
    func testDelayedGroupSequence() {
        let numberOfLoops: Int = 4
        let animations = randomDelayedAnimations(amount: numberOfLoops)
        let totalDuration: TimeInterval = animations.max { $0.totalDuration < $1.totalDuration }?.totalDuration ?? 0
        
        let delay = randomDuration
        let views = animations.map { _ in newView() }
        
        let precision = durationPrecision * TimeInterval(numberOfLoops)
        
        runAnimationTest(duration: delay + totalDuration, precision: precision) { completion, _, _ in
            
            AnimationPlanner.plan {
                Wait(delay)
                Group {
                    for (view, animation) in zip(views, animations) {
                        Sequence {
                            Wait(animation.delay)
                            Animate(duration: animation.duration) {
                                self.performRandomAnimation(on: view)
                            }
                        }
                    }
                }
            }.onComplete { finished in
                completion(finished)
            }
            
        }
    }
}
