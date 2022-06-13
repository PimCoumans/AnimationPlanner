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
    
    /// Runs your animation logic, waits for completion and fails when expected duration varies from provided duration (allowing for precision)
    /// - Parameters:
    ///   - duration: Duration of animimation, or total duration of all animation steps, defaults to random duration
    ///   - precision: Precision to use when comparing expected duration and time to complete animations
    ///   - animations: Closure where animations should be performed with completion closure to call when completed
    ///   - completion: Closure to call when animations have completed
    ///   - usedDuration: Duration for animation, use this argument when no specific duration is provided
    ///   - usedPrecision: Precision for duration check, use this argument when no specific precision is provided
    func runAnimationTest(
        duration: TimeInterval = randomDuration,
        precision: TimeInterval = durationPrecision,
        _ animations: @escaping (
            _ completion: @escaping (Bool) -> Void,
            _ usedDuration: TimeInterval,
            _ usedPrecision: TimeInterval) -> Void
    ) {
        let finishedExpectation = expectation(description: "Animation finished")
        let startTime = CACurrentMediaTime()
        
        let completion: (Bool) -> Void = { finished in
            XCTAssert(finished, "Animation not finished")
            assertDifference(startTime: startTime, duration: duration, precision: precision)
            finishedExpectation.fulfill()
        }
        // perform actual animation stuff
        animations(completion, duration, precision)
        
        waitForExpectations(timeout: duration + precision * 2)
    }
}

// MARK: - Direct UIView animations
extension AnimationPlannerTests {
    
    func testUIViewAnimation() {
        runAnimationTest { completion, duration, _ in
            UIView.animate(withDuration: duration) {
                self.performRandomAnimation()
            } completion: { finished in
                completion(finished)
            }
        }
    }
    
    func testNoopUIViewAnimation() {
        XCTExpectFailure("Noop animations should immediately finish")
        runAnimationTest { completion, duration, _ in
            UIView.animate(withDuration: duration) {
                print("🤫 Do nothing")
            } completion: { finished in
                completion(finished)
            }
        }
    }
}

// TODO: Seperate all these tests into seperate files
// MARK: - Test Builder animations
extension AnimationPlannerTests {
    func testBuilder() {
        let totalDuration: TimeInterval = 1
        let numberOfSteps: TimeInterval = 3
        let duration = totalDuration / numberOfSteps
        
        runAnimationTest(duration: totalDuration) { completion, _, _ in
    
            AnimationPlanner.plan {
                AnimateSpring(duration: duration, damping: 0.8) {
                    self.performRandomAnimation()
                }
                Wait(duration)
                Animate(duration: duration) {
                    self.performRandomAnimation()
                }
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
                AnimateSpring(duration: duration, damping: 0.82) {
                    self.performRandomAnimation()
                }.delayed(delay)
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
                AnimateDelayed(delay: delay, duration: duration) {
                    self.performRandomAnimation()
                }.spring(damping: 0.82)
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
                Loop.through(sequence: durations) { duration in
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
                    AnimateDelayed(delay: animations[index].delay, duration: animations[index].duration) {
                        self.performRandomAnimation()
                    }
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
                Loop.through(sequence: animations) { animation in
                    AnimateDelayed(delay: animation.delay, duration: animation.duration) {
                        self.performRandomAnimation()
                    }
                }
            } completion: { finished in
                completion(finished)
            }
            
        }
    }
}
    
// MARK: - Basic animations
extension AnimationPlannerTests {
    
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
}

// MARK: - Extra handler
extension AnimationPlannerTests {
    
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
    
    /// Uses an `extra` step in a group for the completion handler with a delay for the set random duration
    func testExtraGroupHandler() {
        runAnimationTest { completion, usedDuration, usedPrecision in
            UIView.animateGroup { group in
                group
                    .extra(delay: usedDuration) {
                        completion(true)
                    }
            }
        }
    }
}

// MARK: - Multiple step animations
extension AnimationPlannerTests {
    
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
    
    /// Adds one group with a specific number of animations  which all should be performed simultaneously
    func testGroup() {
        let numberOfSteps: Int = 8
        let durations = randomDurations(amount: numberOfSteps)
        let longestDuration = durations.max()!
        
        runAnimationTest(duration: longestDuration) { completion, _, _ in
            UIView.animateSteps { sequence in
                sequence.addGroup { group in
                    for duration in durations {
                        group.animate(duration: duration) {
                            self.performRandomAnimationOnNewView()
                        }
                    }
                }
            } completion: { finished in
                completion(finished)
            }
        }
    }
    
    /// Adds one group with a specific number of animations  which all should be performed simultaneously
    func testGroupWithDelays() {
        let numberOfSteps: Int = 4
        let animations = randomDelayedAnimations(amount: numberOfSteps)
        
        let totalDuration: TimeInterval = animations.max { $0.totalDuration < $1.totalDuration }?.totalDuration ?? 0
        
        runAnimationTest(duration: totalDuration) { completion, _, _ in
            UIView.animateSteps { sequence in
                sequence.addGroup { group in
                    animations.forEach { animation in
                        group.animate(duration: animation.duration, delay: animation.delay) {
                            self.performRandomAnimationOnNewView()
                        }
                    }
                }
            } completion: { finished in
                completion(finished)
            }
        }
    }
    
    /// Adds one group with a specific number of animations  which all should be performed simultaneously,
    /// but using a the simplified `UIView.animateGroup` method
    func testSimpleGroup() {
        let numberOfSteps: Int = 8
        let durations = randomDurations(amount: numberOfSteps)
        let longestDuration = durations.max()!
        
        runAnimationTest(duration: longestDuration) { completion, _, _ in
            UIView.animateGroup { group in
                for duration in durations {
                    group.animate(duration: duration) {
                        self.performRandomAnimationOnNewView()
                    }
                }
            } completion: { finished in
                completion(finished)
            }
        }
    }
    
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

private let durationPrecision: TimeInterval = 0.05

private func assertDifference(startTime: CFTimeInterval, duration: TimeInterval, precision: TimeInterval = durationPrecision) {
    let finishedTime = CACurrentMediaTime() - startTime
    let difference = finishedTime - duration
    XCTAssert(abs(difference) < precision, "unexpected completion time (difference \(difference) seconds (precision \(precision))")
    print("** DIFFERENCE: \(difference), (precision: \(precision))")
}

private extension AnimationPlannerTests {
    
    class var randomDuration: TimeInterval { TimeInterval.random(in: 0.2...0.8) }
    var randomDuration: TimeInterval { Self.randomDuration }
    
    class func randomDurations(amount: Int) -> [TimeInterval] { (0..<amount).map({ _ in randomDuration }) }
    func randomDurations(amount: Int) -> [TimeInterval] { Self.randomDurations(amount: amount) }
    
    struct RandomAnimation {
        let delay: TimeInterval
        let duration: TimeInterval
        var totalDuration: TimeInterval { delay + duration }
    }
    func randomDelayedAnimations(amount: Int) -> [RandomAnimation] {
        zip(
            randomDurations(amount: amount),
            randomDurations(amount: amount)
        ).map({ RandomAnimation(delay: $0, duration: $1) })
    }
    
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

// from @warpling‘s https://gist.github.com/warpling/21bef9059e47f5aad2f2955d48fd7c0c
extension CAMediaTimingFunction {

    static let linear     = CAMediaTimingFunction(name: .linear)
    static let easeOut    = CAMediaTimingFunction(name: .easeOut)
    static let easeIn     = CAMediaTimingFunction(name: .easeIn)
    static let easeInOut  = CAMediaTimingFunction(name: .easeInEaseOut)
    static let `default`  = CAMediaTimingFunction(name: .default)

    static let sineIn     = CAMediaTimingFunction(controlPoints: 0.45, 0, 1, 1)
    static let sineOut    = CAMediaTimingFunction(controlPoints: 0, 0, 0.55, 1)
    static let sineInOut  = CAMediaTimingFunction(controlPoints: 0.45, 0, 0.55, 1)

    static let quadIn     = CAMediaTimingFunction(controlPoints: 0.43, 0, 0.82, 0.60)
    static let quadOut    = CAMediaTimingFunction(controlPoints: 0.18, 0.4, 0.57, 1)
    static let quadInOut  = CAMediaTimingFunction(controlPoints: 0.43, 0, 0.57, 1)

    static let cubicIn    = CAMediaTimingFunction(controlPoints: 0.67, 0, 0.84, 0.54)
    static let cubicOut   = CAMediaTimingFunction(controlPoints: 0.16, 0.46, 0.33, 1)
    static let cubicInOut = CAMediaTimingFunction(controlPoints: 0.65, 0, 0.35, 1)

    static let quartIn    = CAMediaTimingFunction(controlPoints: 0.81, 0, 0.77, 0.34)
    static let quartOut   = CAMediaTimingFunction(controlPoints: 0.23, 0.66, 0.19, 1)
    static let quartInOut = CAMediaTimingFunction(controlPoints: 0.81, 0, 0.19, 1)

    static let quintIn    = CAMediaTimingFunction(controlPoints: 0.89, 0, 0.81, 0.27)
    static let quintOut   = CAMediaTimingFunction(controlPoints: 0.19, 0.73, 0.11, 1)
    static let quintInOut = CAMediaTimingFunction(controlPoints: 0.9, 0, 0.1, 1)

    static let expoIn     = CAMediaTimingFunction(controlPoints: 1.04, 0, 0.88, 0.49)
    static let expoOut    = CAMediaTimingFunction(controlPoints: 0.12, 0.51, -0.4, 1)
    static let expoInOut  = CAMediaTimingFunction(controlPoints: 0.95, 0, 0.05, 1)

    static let circIn     = CAMediaTimingFunction(controlPoints: 0.6, 0, 1, 0.45)
    static let circOut    = CAMediaTimingFunction(controlPoints: 1, 0.55, 0.4, 1)
    static let circInOut  = CAMediaTimingFunction(controlPoints: 0.82, 0, 0.18, 1)

    static let backIn     = CAMediaTimingFunction(controlPoints: 0.77, -0.63, 1, 1)
    static let backOut    = CAMediaTimingFunction(controlPoints: 0, 0, 0.23, 1.37)
    static let backInOut  = CAMediaTimingFunction(controlPoints: 0.77, -0.63, 0.23, 1.37)

    static let swiftOut   = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
}

