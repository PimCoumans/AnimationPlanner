import AnimationPlanner
import UIKit
import XCTest

class ComplexAnimationTest: AnimationPlannerTests {
    
    /// Creates a pretty complex animation with mutliple groups each containing multiple sequences
    /// Groups can contain sequences that perform their animations in sequence, but each sequence
    /// is running at the same time in each group
    func testSequenceGroup() {
        
        let numberOfGroups = 2
        let numberOfSequences = 2
        let numberOfSteps = 2
        let groups: [[[TimeInterval]]] = (0..<numberOfGroups).map { groupIndex in
            (0..<numberOfSequences).map { sequenceIndex in
                self.randomDurations(amount: numberOfSteps)
            }
        }
        
        let groupDurations = groups.map { $0.map({ $0.totalDuration() }).longestDuration() }
        let totalDuration = groupDurations.totalDuration()
        
        let precision = durationPrecision * TimeInterval(numberOfSteps)
        
        runAnimationBuilderTest(duration: totalDuration, precision: precision) { _, _ in
            
            AnimationPlanner.plan {
                for group in groups {
                    Group {
                        for sequence in group {
                            Sequence {
                                let view = self.newView()
                                for duration in sequence {
                                    Animate(duration: duration) {
                                        self.performRandomAnimation(on: view)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
        }
    }
}
