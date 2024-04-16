import UIKit

/// Performs the provided handler in between your actual animations.
/// Typically used for setting up state before an animation or creating side-effects like haptic feedback.
public struct Extra: SequenceAnimatable, GroupAnimatable {
    public let duration: TimeInterval = 0
    
    /// Work item used for actually executing the closure
    private let workItem: DispatchWorkItem
    
    public init(perform: @escaping () -> Void) {
        workItem = DispatchWorkItem(block: perform)
    }
}

extension Extra: PerformsAnimations {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        let timing = timingParameters(leadingDelay: leadingDelay)
        
        guard timing.delay > 0 else {
            workItem.perform()
            completion?(true)
            return
        }
        
        workItem.notify(queue: .main) { [weak workItem] in
            let isFinished = workItem?.isCancelled != false
            completion?(isFinished)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timing.delay, execute: workItem)
    }
    
    public func stop() {
        workItem.cancel()
    }
}
