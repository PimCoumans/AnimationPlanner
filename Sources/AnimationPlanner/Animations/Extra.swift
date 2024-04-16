import UIKit

/// Performs the provided handler in between your actual animations.
/// Typically used for setting up state before an animation or creating side-effects like haptic feedback.
public struct Extra: SequenceAnimatable, GroupAnimatable {
    private let id = UUID()
    public let duration: TimeInterval = 0
    
    public var perform: () -> Void
    public init(perform: @escaping () -> Void) {
        self.perform = perform
    }
}

extension Extra {
    private static var allowedAnimations: Set<UUID> = []
}

extension Extra: PerformsAnimations {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        let timing = timingParameters(leadingDelay: leadingDelay)
        Self.allowedAnimations.insert(id)
        let animation: () -> Void = {
            guard Self.allowedAnimations.contains(id) else {
                completion?(false)
                return
            }
            self.perform()
            Self.allowedAnimations.remove(id)
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
    
    public func stop() {
        Self.allowedAnimations.remove(id)
    }
}
