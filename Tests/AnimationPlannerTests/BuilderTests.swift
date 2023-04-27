import AnimationPlanner
import Foundation
import UIKit
import XCTest

class BuilderTests: AnimationPlannerTests {
    
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
        
        runAnimationBuilderTest(duration: longestAnimation.totalDuration, precision: precision) { _, _ in
            AnimationPlanner.plan {
                waitStartingGroup
            }
        }
        
        runAnimationBuilderTest(duration: longestAnimation.totalDuration, precision: precision) { _, _ in
            AnimationPlanner.plan {
                waitEndingGroup
            }
        }
    }
    
    func testEmptyBuilder() {
        
        runAnimationBuilderTest(duration: 0) { _, _ in
    
            AnimationPlanner.plan {
                Extra {
                    print("👋")
                }
            }
            
        }
    }
    
    func testBuilder() {
        let totalDuration: TimeInterval = 1
        let numberOfSteps: TimeInterval = 3
        let duration = totalDuration / numberOfSteps
        
        runAnimationBuilderTest(duration: totalDuration) { _, _ in
    
            AnimationPlanner.plan {
                Animate(duration: duration) {
                    self.performRandomAnimation()
                }
                Wait(duration)
                Animate(duration: duration) {
                    self.performRandomAnimation()
                }
                .spring(damping: 0.8)
            }
            
        }
    }
    
    func testBuilderModifiers() {
        let totalDuration: TimeInterval = 1
        let numberOfSteps: TimeInterval = 3
        let duration = totalDuration / numberOfSteps
        
        runAnimationBuilderTest(duration: totalDuration) { _, _ in
            
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
            }
            
        }
    }
    
    func testBuilderContainerModifiers() {
        let totalDuration: TimeInterval = 1
        let numberOfSteps: TimeInterval = 1
        let duration = totalDuration / numberOfSteps
        
        runAnimationBuilderTest(duration: totalDuration) { _, _ in
            
            AnimationPlanner.plan {
                Animate(duration: duration) {
                    self.performRandomAnimation()
                }
                .spring(damping: 0.82)
                .options(.allowUserInteraction)
            }
            
        }
    }
    
    func testDelayedSpring() {
        let duration: TimeInterval = 0.5
        let delay: TimeInterval = 0.25
        let totalDuration = delay + duration
        runAnimationBuilderTest(duration: totalDuration) { _, _ in
            
            AnimationPlanner.group {
                Animate(duration: duration) {
                    self.performRandomAnimation()
                }
                .spring(damping: 0.82)
                .delayed(delay)
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
        
        runAnimationBuilderTest(duration: totalDuration) { _, _ in
            
            AnimationPlanner.group {
                Animate(duration: duration) {
                    self.performRandomAnimation()
                }
                .delayed(delay)
                .spring(damping: 0.82)
            }
            
        }
    }
    
    func testGroupSequence() {
        let numberOfLoops: Int = 4
        let animations = randomDelayedAnimations(amount: numberOfLoops)
        let totalDuration: TimeInterval = animations.max { $0.totalDuration < $1.totalDuration }?.totalDuration ?? 0
        
        runAnimationBuilderTest(duration: totalDuration) { usedDuration, usedPrecision in
            AnimationPlanner.group {
                for animation in animations {
                    Sequence {
                        Wait(animation.delay)
                        Animate(duration: animation.duration) {
                            self.performRandomAnimation()
                        }
                    }
                }
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
        
        runAnimationBuilderTest(duration: delay + totalDuration, precision: precision) { _, _ in
            
            AnimationPlanner.plan {
                Wait(delay)
                Group {
                    zip(views, animations).mapGroup { view, animation in
                        Sequence {
                            Wait(animation.delay)
                            Animate(duration: animation.duration) {
                                self.performRandomAnimation(on: view)
                            }
                        }
                    }
                }
            }
            
        }
    }
}
