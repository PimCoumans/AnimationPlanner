import UIKit

/// Perfoms the provided handler in between your actual animations.
/// Typically used for setting up state before an animation or creating side-effects like haptic feedback.
public struct Extra: SequenceAnimatable, GroupAnimatable {
    public let duration: TimeInterval = 0
    
    /// Work item used for actually executing the closure
    private var workItem: DispatchWorkItem?
    
    public var perform: () -> Void
    public init(perform: @escaping () -> Void) {
        self.perform = perform
    }
}

extension Extra: PerformsAnimations {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) -> PerformsAnimations {
        let timing = timingParameters(leadingDelay: leadingDelay)
        
        guard timing.delay > 0 else {
            perform()
            completion?(true)
            return self
        }
        
        let workItem = DispatchWorkItem {
            self.perform()
        }
        
        workItem.notify(queue: .main) { [weak workItem] in
            let isFinished = workItem.map { !$0.isCancelled } ?? true
            completion?(isFinished)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timing.delay, execute: workItem)
        return mutate { $0.workItem = workItem }
    }
	
	public func stop() {
        workItem?.cancel()
    }
}
