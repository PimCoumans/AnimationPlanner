import UIKit
import XCTest
import AnimationPlanner

class AnimationPlannerTests: XCTestCase {
    
    var window: UIWindow!
    var view: UIView!
    
    override func setUp() {
        window = UIWindow(frame: UIScreen.main.bounds)
        view = newView()
        window.addSubview(view)
    }
    
    override func tearDown() {
        window.resignKey()
        view.removeFromSuperview()
        window = nil
        view = nil
    }
    
    /// Runs your animation logic, waits for completion and fails when expected duration varies from provided duration (allowing for precision). Adds a default completion handler to the returned `RunningSequence`.
    /// - Parameters:
    ///   - duration: Duration of animation, or total duration of all animation steps, defaults to random duration
    ///   - precision: Precision to use when comparing expected duration and time to complete animations
    ///   - expectFinished: Whether the animation are expected to be properly finished
    ///   - animations: Closure where animations should be performed with completion closure to call when completed
    ///   - completion: Closure to call when animations have completed
    ///   - usedDuration: Duration for animation, use this argument when no specific duration is provided
    ///   - usedPrecision: Precision for duration check, use this argument when no specific precision is provided
    func runAnimationBuilderTest(
        duration: TimeInterval = randomDuration,
        precision: TimeInterval = durationPrecision,
        expectFinished: Bool = true,
        _ animations: @escaping (
            _ usedDuration: TimeInterval,
            _ usedPrecision: TimeInterval) -> RunningSequence?
    ) {
        runAnimationTest(duration: duration, precision: precision, expectFinished: expectFinished) { completion, usedDuration, usedPrecision in
            let runningSequence = animations(duration, precision)
            XCTAssertNotNil(runningSequence)
            runningSequence?.onComplete(completion)
        }
    }
    
    /// Runs your animation logic, waits for completion and fails when expected duration varies from provided duration (allowing for precision). Add the completion handler to the returned `RunningSequence` object when only using `AnimationPlanner.plan` or `.group`. Otherwise use `runAnimationTest`
    /// - Parameters:
    ///   - duration: Duration of animation, or total duration of all animation steps, defaults to random duration
    ///   - precision: Precision to use when comparing expected duration and time to complete animations
    ///   - expectFinished: Whether the animation are expected to be properly finished
    ///   - animations: Closure where animations should be performed with completion closure to call when completed
    ///   - completion: Closure to call when animations have completed
    ///   - usedDuration: Duration for animation, use this argument when no specific duration is provided
    ///   - usedPrecision: Precision for duration check, use this argument when no specific precision is provided
    func runAnimationTest(
        duration: TimeInterval = randomDuration,
        precision: TimeInterval = durationPrecision,
        expectFinished: Bool = true,
        _ animations: @escaping (
            _ completion: @escaping (Bool) -> Void,
            _ usedDuration: TimeInterval,
            _ usedPrecision: TimeInterval) -> Void
    ) {
        let finishedExpectation = expectation(description: "Animation finished")
        let startTime = CACurrentMediaTime()
        
        let completion: (Bool) -> Void = { finished in
            if finished != expectFinished {
                if expectFinished {
                    XCTFail("Animations should complete finished")
                } else {
                    XCTFail("Animations should complete interrupted")
                }
            }
            assertDifference(startTime: startTime, duration: duration, precision: precision)
            finishedExpectation.fulfill()
        }
        
        animations(completion, duration, precision)
        
        wait(for: [finishedExpectation], timeout: duration + precision * 2)
    }
}

let durationPrecision: TimeInterval = 0.05

func assertDifference(startTime: CFTimeInterval, duration: TimeInterval, precision: TimeInterval = durationPrecision) {
    let finishedTime = CACurrentMediaTime() - startTime
    let difference = finishedTime - duration
    XCTAssert(abs(difference) < precision, "unexpected completion time (difference \(difference) seconds (precision \(precision))")
}

fileprivate extension CGFloat {
    
    private static let colorRange: Range<Self> = 0.1..<1.0
    private static let tinyRange: Range<Self> = 0.8..<1.2
    private static let smallRange: Range<Self> = 4..<6
    private static let mediumRange: Range<Self> = 8..<12
    private static let largeRange: Range<Self> = 200..<400
    
    static var color: Self { Self.random(in: colorRange) }
    static var tiny: Self { Self.random(in: tinyRange) }
    static var small: Self { Self.random(in: smallRange) }
    static var medium: Self { Self.random(in: mediumRange) }
    static var large: Self { Self.random(in: largeRange) }
}

extension Array where Element == TimeInterval {
    func totalDuration() -> Element {
        reduce(0, +)
    }
    func longestDuration() -> Element {
        self.max()!
    }
}

extension AnimationPlannerTests {
    
    class var randomDuration: TimeInterval { TimeInterval.random(in: 0.2...0.6) }
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
        let view = UIView(frame: CGRect(
            x: .large,
            y: .large,
            width: .large,
            height: .large
        ))
        window.addSubview(view)
        return view
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
            view.frame = CGRect(x: .small, y: .small, width: .medium, height: .medium)
        case .largeFrame:
            view.frame = CGRect(x: .small, y: .small, width: .large, height: .large)
        case .transformScale:
            view.transform = CGAffineTransform(scaleX: .tiny, y: .tiny)
        case .transformTranslate:
            view.transform = CGAffineTransform(translationX: .medium, y: .medium)
        case .backgroundColor:
            view.backgroundColor = UIColor(red: .color, green: .color, blue: .color, alpha: .color)
        }
    }
}
