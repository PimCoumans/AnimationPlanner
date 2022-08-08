import AnimationPlanner
import UIKit

class GroupTests: AnimationPlannerTests {
    
    /// Adds one group with a specific number of animations  which all should be performed simultaneously
    func testGroup() {
        let numberOfSteps: Int = 8
        let durations = randomDurations(amount: numberOfSteps)
        let longestDuration = durations.max()!
        
        runAnimationBuilderTest(duration: longestDuration) { _, _ in
            
            AnimationPlanner.plan {
                Group {
                    durations.mapAnimations { duration in
                        Animate(duration: duration) {
                            self.performRandomAnimation()
                        }
                    }
                }
            }
            
        }
    }
    
    /// Adds one group with a specific number of animations  which all should be performed simultaneously,
    /// but using a the simplified `UIView.animateGroup` method
    func testGroupMethod() {
        let numberOfSteps: Int = 8
        let durations = randomDurations(amount: numberOfSteps)
        let longestDuration = durations.max()!
        
        runAnimationBuilderTest(duration: longestDuration) { _, _ in
            
            AnimationPlanner.group {
                durations.mapAnimations { duration in
                    Animate(duration: duration) {
                        self.performRandomAnimation()
                    }
                }
            }
            
        }
    }
    
    func testDelayedGroup() {
        let totalDuration: TimeInterval = 5
        let numberOfSteps: TimeInterval = 4
        let duration = totalDuration / numberOfSteps
        let delay: TimeInterval = 1
        
        runAnimationBuilderTest(duration: totalDuration + delay) { _, _ in
            
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
        
        runAnimationBuilderTest(duration: totalDuration) { _, _ in
            
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
            }
            
        }
        
    }
    
    /// Adds one group with a specific number of animations  which all should be performed simultaneously
    func testGroupWithDelays() {
        let numberOfSteps: Int = 4
        let animations = randomDelayedAnimations(amount: numberOfSteps)
        
        let totalDuration: TimeInterval = animations.max { $0.totalDuration < $1.totalDuration }?.totalDuration ?? 0
        
        runAnimationBuilderTest(duration: totalDuration) { _, _ in
            
            AnimationPlanner.plan {
                Group {
                    animations.mapAnimations { animation in
                        AnimateDelayed(delay: animation.delay, duration: animation.duration) {
                            self.performRandomAnimation()
                        }
                    }
                }
            }
            
        }
    }
    
    /// Uses an `extra` step in a group for the completion handler with a delay for the set random duration
    func testExtraGroupHandler() {
        runAnimationTest { completion, usedDuration, usedPrecision in
            
            AnimationPlanner.group {
                Extra {
                    completion(true)
                }.delayed(usedDuration)
            }
            
        }
    }
	
    /// Animates multiple sequences simulatiously, each with an increasing offset in their contained animations
    func testGroupsWithOffsetSequenceAnimations() {
        let numberOfGroups: Int = 4
        let animations = randomDurations(amount: 2)
        let delayMultiplier: Double = 0.2
        
        let totalDelay: TimeInterval = Double(numberOfGroups - 1) * delayMultiplier
        let totalDuration: TimeInterval = totalDelay + animations.reduce(0, { $0 + $1 })
        
        let views = (0..<numberOfGroups).map { _ in
            newView()
        }
        
        runAnimationBuilderTest(duration: totalDuration) { _, _ in
            AnimationPlanner.group {
                Loop(for: numberOfGroups) { index in
                    let delay = Double(index) * delayMultiplier
                    Sequence {
                        Wait(delay)
                        animations.mapAnimations { duration in
                            Animate(duration: duration) {
                                self.performRandomAnimation(on: views[index])
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Animates multiple sequences simulatiously, each with an increasinging delay added through a delay modifier
    func testGroupsWithDelayedSequences() {
        let numberOfGroups: Int = 4
        let animations = randomDurations(amount: 2)
        let delayMultiplier: Double = 0.2
        
        let totalDelay: TimeInterval = Double(numberOfGroups - 1) * delayMultiplier
        let totalDuration: TimeInterval = totalDelay + animations.reduce(0, { $0 + $1 })
        
        let views = (0..<numberOfGroups).map { _ in
            newView()
        }
        
        runAnimationBuilderTest(duration: totalDuration) { _, _ in
            AnimationPlanner.group {
                Loop(for: numberOfGroups) { index in
                    let delay = Double(index) * delayMultiplier
                    Sequence {
                        animations.mapAnimations { duration in
                            Animate(duration: duration) {
                                self.performRandomAnimation(on: views[index])
                            }
                        }
                    }.delayed(delay)
                }
            }
        }
    }
    
}
