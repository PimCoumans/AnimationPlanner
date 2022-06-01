import XCTest
import AnimationPlanner

final class AnimationPlannerTests: XCTestCase {
    
    var window: UIWindow!
    var view: UIView!
    
    override func setUp() {
        window = UIWindow(frame: UIScreen.main.bounds)
        view = UIView(frame: window.bounds.insetBy(dx: 100, dy: 100))
        window.addSubview(view)
    }
    
    override func tearDown() {
        window.resignKey()
        view.removeFromSuperview()
        window = nil
        view = nil
    }
    
    func testBasicAnimation() throws {
        let finishedExpectation = expectation(description: "Animation finished")
        let duration: TimeInterval = 2
        let startTime = CACurrentMediaTime()
        UIView.animateSteps { sequence in
            sequence.add(duration: duration) {
                self.performRandomAnimation()
            }
        } completion: { finished in
            XCTAssert(finished, "Animation not finished")
            assertDifference(startTime: startTime, duration: duration)
            finishedExpectation.fulfill()
        }
        waitForExpectations(timeout: duration + (durationPrecision * 2))
    }
    
    func testMultipleSteps() throws {
        let finishedExpectation = expectation(description: "Animation finished")
        var totalDuration: TimeInterval = 0
        let startTime = CACurrentMediaTime()
        let numberOfSteps: Int = 4
        let precision = durationPrecision * TimeInterval(numberOfSteps)
        
        UIView.animateSteps { sequence in
            for _ in 0..<numberOfSteps {
                let duration = self.randomDuration
                totalDuration += duration
                sequence.add(duration: duration) {
                    self.performRandomAnimation()
                }
            }
        } completion: { finished in
            XCTAssert(finished, "Animation not finished")
            assertDifference(startTime: startTime, duration: totalDuration, precision: precision)
            finishedExpectation.fulfill()
        }
        waitForExpectations(timeout: totalDuration + (precision * 2))
    }
    
    func testStepsWithDelay() throws {
        let finishedExpectation = expectation(description: "Animation finished")
        var totalDuration: TimeInterval = 0
        let startTime = CACurrentMediaTime()
        let numberOfSteps: Int = 4
        let precision = durationPrecision * TimeInterval(numberOfSteps)
        
        UIView.animateSteps { sequence in
            for _ in 0..<numberOfSteps {
                let duration = self.randomDuration
                totalDuration += duration
                sequence.add(duration: duration) {
                    self.performRandomAnimation()
                }
                let delay = self.randomDuration
                totalDuration += delay
                sequence.delay(delay)
            }
        } completion: { finished in
            XCTAssert(finished, "Animation not finished")
            assertDifference(startTime: startTime, duration: totalDuration, precision: precision)
            finishedExpectation.fulfill()
        }
        waitForExpectations(timeout: totalDuration + (precision * 2))
    }
    
    func testGroup() throws {
        let finishedExpectation = expectation(description: "Animation finished")
        var longestDuration: TimeInterval = 0
        let startTime = CACurrentMediaTime()
        let numberOfSteps: Int = 8
        
        UIView.animateSteps { sequence in
            sequence.addGroup { group in
                for _ in 0..<numberOfSteps {
                    let duration = self.randomDuration
                    longestDuration = max(longestDuration, duration)
                    group.animate(duration: duration) {
                        self.performRandomAnimationOnNewView()
                    }
                }
            }
        } completion: { finished in
            XCTAssert(finished, "Animation not finished")
            assertDifference(startTime: startTime, duration: longestDuration)
            finishedExpectation.fulfill()
        }
        waitForExpectations(timeout: longestDuration * 2)
    }
    
    func testSimpleGroup() {
        let finishedExpectation = expectation(description: "Animation finished")
        var longestDuration: TimeInterval = 0
        let startTime = CACurrentMediaTime()
        let numberOfSteps: Int = 8
        
        UIView.animateGroup { group in
            for _ in 0..<numberOfSteps {
                let duration = self.randomDuration
                longestDuration = max(longestDuration, duration)
                group.animate(duration: duration) {
                    self.performRandomAnimationOnNewView()
                }
            }
        } completion: { finished in
            XCTAssert(finished, "Animation not finished")
            assertDifference(startTime: startTime, duration: longestDuration)
            finishedExpectation.fulfill()
        }
        
        waitForExpectations(timeout: longestDuration + (durationPrecision * 2))
    }
    
    func testSequenceGroup() {        
        let finishedExpectation = expectation(description: "Animation finished")
        var totalDuration: TimeInterval = 0
        let startTime = CACurrentMediaTime()
        let numberOfSteps: Int = 6
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

private let durationPrecision: TimeInterval = 0.05

private func assertDifference(startTime: CFTimeInterval, duration: TimeInterval, precision: TimeInterval = durationPrecision) {
    let finishedTime = CACurrentMediaTime() - startTime
    let difference = finishedTime - duration
    XCTAssert(abs(difference) < precision, "Animation completion time too far off (by \(difference) seconds (precision \(precision)")
    print("** DIFFERENCE: \(difference), (precision: \(precision))")
}

extension AnimationPlannerTests {
    
    var randomDuration: TimeInterval { TimeInterval.random(in: 0.2...0.8) }
    
    func performRandomAnimation() {
        performRandomAnimation(on: view!)
    }
    
    func newView() -> UIView {
        let view = UIView()
        window.addSubview(view)
        return view
    }
    
    func performRandomAnimationOnNewView() {
        performRandomAnimation(on: newView())
    }
    
    func performRandomAnimation(on view: UIView) {
        enum RandomAnimation: CaseIterable {
            case smallFrame
            case largeFrame
            case transformScale
            case transformTranslate
            case backgroundColor
        }
        switch RandomAnimation.allCases.randomElement()! {
        case .smallFrame:
            view.frame = [
                CGRect(x: 10, y: 10, width: 10, height: 10),
                CGRect(x: 11, y: 11, width: 11, height: 11)
            ].first(where: {$0 != view.frame })!
        case .largeFrame:
            view.frame = [
                CGRect(x: 5, y: 5, width: 200, height: 600),
                CGRect(x: 4, y: 4, width: 202, height: 602)
            ].first(where: {$0 != view.frame })!
        case .transformScale:
            view.transform = [
                CGAffineTransform(scaleX: 1.5, y: 1.5),
                CGAffineTransform(scaleX: 1.7, y: 1.7)
            ].first(where: {$0 != view.transform })!
        case .transformTranslate:
            view.transform = [
                CGAffineTransform(translationX: 20, y: 20),
                CGAffineTransform(translationX: 100, y: 100)
            ].first(where: {$0 != view.transform })!
        case .backgroundColor:
            view.backgroundColor = [
                .systemBlue,
                .systemPink
            ].first(where: { $0 != view.backgroundColor })
        }
    }
}
