import UIKit
import XCTest

class AnimationPlannerTests: XCTestCase {
    
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

let durationPrecision: TimeInterval = 0.05

func assertDifference(startTime: CFTimeInterval, duration: TimeInterval, precision: TimeInterval = durationPrecision) {
    let finishedTime = CACurrentMediaTime() - startTime
    let difference = finishedTime - duration
    XCTAssert(abs(difference) < precision, "unexpected completion time (difference \(difference) seconds (precision \(precision))")
    print("** DIFFERENCE: \(difference), (precision: \(precision))")
}

extension AnimationPlannerTests {
    
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
