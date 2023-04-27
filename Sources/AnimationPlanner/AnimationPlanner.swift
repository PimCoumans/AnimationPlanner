import UIKit

/// Chain multiple `UIView` animations with a clear declarative syntax, describing each step along the way.
/// Start by typing `AnimationPlanner.plan` and  provide all of your animations from the `animations` closure.
///
/// Begin planning your animation by using either of the following static methods:
/// - ``plan(animations:)`` start a sequence animation where all animations are performed in order.
/// - ``group(animations:)`` start a group animation where all animations are performed simultaneously.
///
/// - Tip:  To get started,  read <doc:creating-basic-animation-sequence> and get up to speed on how to use AnimationPlanner,
/// or go through the whole documentation on ``AnimationPlanner`` to get an overview of all the available functionalities.
public struct AnimationPlanner {
    
    /// Start a new animation sequence where animations added will be performed in order, meaning a subsequent animation starts right after the previous finishes.
    ///
    /// ```swift
    /// AnimationPlanner.plan {
    ///     Animate(duration: 0.25) { view.backgroundColor = .systemRed }
    ///     Wait(0.5)
    ///     Animate(duration: 0.5) {
    ///         view.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
    ///     }.spring(damping: 0.68)
    /// }
    /// ```
    /// - Parameters:
    ///   - animations: Add each animation using this closure. Animation added to a sequence should conform to ``GroupAnimatable``.
    /// - Returns: Instance of ``RunningSequence`` to keep track of and stop animations
    @discardableResult
    public static func plan(
        @SequenceBuilder animations builder: () -> [SequenceAnimatable]
    ) -> RunningSequence {
        RunningSequence(animations: builder())
            .animate()
    }
    
    /// Start a new group animation where animations added will be performed simultaneously, meaning all animations run at the same time.
    ///
    /// ```swift
    /// AnimationPlanner.group {
    ///     Animate(duration: 0.5) {
    ///         view.frame.origin.y = 0
    ///     }.delayed(0.15)
    ///     Animate(duration: 0.3) {
    ///         view.backgroundColor = .systemBlue
    ///     }.delayed(0.2)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - animations: Add each animation using this closure. Animation added to a group should conform to ``GroupAnimatable``.
    /// - Returns: Instance of ``RunningSequence`` to keep track of and stop animations
    @discardableResult
    public static func group(
        @GroupBuilder animations builder: () -> [GroupAnimatable]
    ) -> RunningSequence {
        plan {
            Group(animations: builder)
        }
    }
}
