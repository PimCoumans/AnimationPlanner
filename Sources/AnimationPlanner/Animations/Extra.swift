import UIKit

/// Perfoms the provided handler in between your actual animations.
/// Typically used for setting up state before an animation or creating side-effects like haptic feedback.
public struct Extra: SequenceAnimatable, GroupAnimatable {
    public let duration: TimeInterval = 0
    
    public var perform: () -> Void
    public init(perform: @escaping () -> Void) {
        self.perform = perform
    }
}

extension Extra: PerformsAnimations {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        let timing = timingParameters(leadingDelay: leadingDelay)
        
        let animation: () -> Void = {
            self.perform()
            completion?(true)
        }
        guard timing.delay > 0 else {
            animation()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + timing.delay) {
            animation()
        }
    }
}
