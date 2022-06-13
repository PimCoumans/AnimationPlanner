import AnimationPlanner
import UIKit
import XCTest

class ComplexAnimationTest: AnimationPlannerTests {
    /// Creates a pretty complex animation with mutliple groups each containing multiple sequences
    /// Groups can contain sequences that perform their animations in sequence, but each sequence
    /// is running at the same time in each group
    func testSequenceGroup() {
        let finishedExpectation = expectation(description: "Animation finished")
        var totalDuration: TimeInterval = 0
        let startTime = CACurrentMediaTime()
        let numberOfSteps: Int = 2
        let maxNumberOfSequences: Int = 2
        let maxNumberOfSequenceSteps: Int = 2
        
        let precision = durationPrecision * TimeInterval(numberOfSteps)
        
        UIView.animateSteps { sequence in
            print("Running \(numberOfSteps) subsequent groups")
            
            for groupIndex in 0..<numberOfSteps {
                var longestDuration: TimeInterval = 0
                
                sequence.addGroup { group in
                    
                    let count = Int.random(in: 2...maxNumberOfSequences)
                    print("Adding group \(groupIndex) with \(count) sequences")
                    
                    for subSquenceIndex in 0..<count {
                        var sequenceDuration: TimeInterval = 0
                        
                        group.animateSteps { sequence in
                            
                            let view = self.newView()
                            let stepCount = Int.random(in: 2...maxNumberOfSequenceSteps)
                            print("Adding \(stepCount) steps to sequence \(subSquenceIndex)")
                            
                            for stepIndex in 0..<stepCount {
                                let duration = self.randomDuration
                                sequenceDuration += duration
                                sequence.add(duration: duration) {
                                    // Yikes we‘re 9 levels deep
                                    print("Animating step: \(stepIndex) in sequence: \(subSquenceIndex) in group: \(groupIndex)")
                                    self.performRandomAnimation(on: view)
                                }
                            }
                        }
                        longestDuration = max(longestDuration, sequenceDuration)
                    }
                }
                totalDuration += longestDuration
            }
        } completion: { finished in
            XCTAssert(finished, "Animation not finished")
            assertDifference(startTime: startTime, duration: totalDuration, precision: precision)
            finishedExpectation.fulfill()
        }
        
        waitForExpectations(timeout: totalDuration + (durationPrecision * 2))
        
    }
}
