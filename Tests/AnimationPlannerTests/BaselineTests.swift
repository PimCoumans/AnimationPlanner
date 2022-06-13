import XCTest
import AnimationPlanner

final class BaselineTests: AnimationPlannerTests {
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
