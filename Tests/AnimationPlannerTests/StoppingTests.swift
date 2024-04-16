import AnimationPlanner
import XCTest

class StoppingTests: AnimationPlannerTests {
    
    func testWorkItemCancelling() {
        runAnimationTest { completion, usedDuration, usedPrecision in
            let workItem = DispatchWorkItem {
                XCTFail("Scheduled and subsequently cancelled work item should never be executed")
            }
            workItem.notify(queue: .main) { [weak workItem] in
                let finished = workItem?.isCancelled == false
                XCTExpectFailure {
                    completion(finished)
                }
            }
            let delayTime: DispatchTime = .now() + usedDuration
            let cancelTime: DispatchTime = .now() + usedDuration / 2
            DispatchQueue.main.asyncAfter(deadline: delayTime, execute: workItem)
            DispatchQueue.main.asyncAfter(deadline: cancelTime) {
                workItem.cancel()
            }
        }
    }
    
    func testExtraStopping() {
        let duration = randomDuration
        let runningSequence = AnimationPlanner.plan {
            Wait(duration)
            Extra {
                XCTFail("Extra should never be called")
            }
        }
        
        let stopDelay = duration - durationPrecision
        
        DispatchQueue.main.asyncAfter(deadline: .now() + stopDelay) {
            runningSequence.stopAnimations()
        }
        
        runAnimationBuilderTest(duration: duration, expectFinished: false) { usedDuration, usedPrecision in
            runningSequence
        }
    }
    
    func testBasicStopping() {
        // Run a basic number of animations after which the sequence should be stopped.
        // As the stopping is happening from an extra right after the expected animations
        // the timing should be just right
        let animations = randomDelayedAnimations(amount: 4)
        let totalDuration: TimeInterval = animations.reduce(0, { $0 + $1.totalDuration })
        
        var runningSequence: RunningSequence?
        runningSequence = AnimationPlanner.plan {
            for animation in animations {
                Wait(animation.delay)
                Animate(duration: animation.duration) {
                    self.performRandomAnimation()
                }
            }
            
            Extra {
                // Cancelling animation after planned animation
                runningSequence?.stopAnimations()
            }
            Wait(randomDuration)
            Animate(duration: randomDuration) {
                XCTFail("Animation should never be performed")
            }
            Wait(randomDuration)
            Extra {
                XCTFail("Extra should never be performed")
            }
        }
        
        runAnimationBuilderTest(duration: totalDuration, expectFinished: false) { usedDuration, usedPrecision in
            runningSequence!
        }
    }
    
    func testGroupStopping() {
        // Runs a number of sequences in parallel with each a specific number of animations
        // Then halfway through the expected duration of the animations, the animations are
        // stopped. Each animation that is executed after animations should be stopped trigger
        // a failure.
        
        let numberOfSequences = 4
        let numberOfAnimations = 4
        let sequenceIndexMultiplier: TimeInterval = 0.5
        let animations = randomDelayedAnimations(amount: numberOfAnimations)
        let precision = durationPrecision * TimeInterval(numberOfSequences)
        let totalDuration = animations.reduce(0, { $0 + $1.totalDuration }) + TimeInterval(numberOfSequences - 1) * sequenceIndexMultiplier
        
        let pauseDelay: TimeInterval = totalDuration / 2
        let pauseOffset = CACurrentMediaTime() + pauseDelay
        
        let runningSequence = AnimationPlanner.group {
            for sequenceIndex in 0..<numberOfSequences {
                Sequence {
                    let sequenceDelay = TimeInterval(sequenceIndex) * sequenceIndexMultiplier
                    Wait(sequenceDelay)
                    let view = newView()
                    for animation in animations {
                        Wait(animation.delay)
                        Animate(duration: animation.duration) {
                            XCTAssert(CACurrentMediaTime() < (pauseOffset + durationPrecision))
                            self.performRandomAnimation(on: view)
                        }
                    }
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + pauseDelay) {
            runningSequence.stopAnimations()
        }
        
        runAnimationBuilderTest(duration: pauseDelay, precision: precision, expectFinished: false) { _, _ in
            runningSequence
        }
    }
}
