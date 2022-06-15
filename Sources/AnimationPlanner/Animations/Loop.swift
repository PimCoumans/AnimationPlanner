import UIKit

/// Loop through a sequence or for a specified repeat count to easily repeat multiple animation.
///
/// Either create a `Loop` with the default initializer where you set `repeatCount` or use the static method ``through(_:animations:)-3pcny`` to loop through an existing array.
///
/// ```swift
/// Loop(for: numberOfLoops) { index in
///    Animate(duration: 0.2) {
///        view.frame.origin += 10
///    }
///    Wait(0.5)
/// }
/// ```
public struct Loop<Looped> {
    /// Total duration of loop. Sum of all animations when animated in sequence, duration of longest animation when animated in a group.
    public var duration: TimeInterval
    /// All animations created in the loop.
    public let animations: [Looped]
    
    fileprivate init(
        repeatCount: Int,
        @AnimationBuilder builder: (_ index: Int) -> [Looped]
    ) {
        self.animations = (0..<repeatCount).flatMap(builder)
        
        if Looped.self == AnimatesInSequence.self, let animations = animations as? [AnimatesInSequence] {
            duration = animations.reduce(0, { $0 + $1.duration })
        } else if Looped.self == AnimatesSimultaneously.self, let animations = animations as? [AnimatesSimultaneously] {
            duration = animations.max(by: { $0.totalDuration < $1.totalDuration }).map(\.totalDuration) ?? 0
        } else {
            fatalError("Animations provided through Loop don’t comform to any animatable type")
        }
    }
    
    fileprivate static func map<S: Swift.Sequence>(
        _ sequence: S,
        @AnimationBuilder with builder: (S.Element) -> [Looped]
    ) -> [Looped] {
        sequence.flatMap(builder)
    }
}

extension Loop: SequenceAnimatesConvertible where Looped == AnimatesInSequence {
    public func asSequence() -> [AnimatesInSequence] {
        animations
    }
    
    /// Creates a new Loop that repeats for the given amount of times.
    /// - Parameters:
    ///   - repeatCount: How many times the loop should repeat. The index of each loop is provided as a argument in the `animations` closure
    ///   - animations: Add each animation from within this closure. Animations added to this loop should conform to ``AnimatesInSequence``
    public init(
        for repeatCount: Int,
        @AnimationBuilder animations builder: (_ index: Int) -> [AnimatesInSequence]
    ) {
        self.init(repeatCount: repeatCount, builder: builder)
    }
    
    /// Loop through a sequence of values, like objects in an array or a range of numbers
    /// - Parameters:
    ///   - sequence: Sequence to loop through, each element will be handled in the `animations` closure
    ///   - animations: Add each animation from within this closure. Animations added to this loop should conform to ``AnimatesInSequence``
    /// - Returns: Sequence of all animations created in the `animation` closure
    public static func through<S: Swift.Sequence>(
        _ sequence: S,
        @AnimationBuilder animations builder: (S.Element) -> [AnimatesInSequence]
    ) -> [AnimatesInSequence] {
        map(sequence, with: builder)
    }
}

extension Loop: PerformsAnimations where Looped == AnimatesInSequence {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        // FIXME: Sequence Loops don't animate yet, should be implemeted in Phase 2
        fatalError("Sequence animation not yet implemented")
    }
}

extension Loop: SimultaneouslyAnimatesConvertible where Looped == AnimatesSimultaneously {
    public func asGroup() -> [AnimatesSimultaneously] {
        animations
    }
    
    /// Creates a new Loop that repeats for the given amount of times.
    /// - Parameters:
    ///   - repeatCount: How many times the loop should repeat. The index of each loop is provided as a argument in the `animations` closure
    ///   - animations: Add each animation from within this closure. Animations added to this loop should conform to ``AnimatesSimultaneously``
    public init(
        for repeatCount: Int,
        @AnimationBuilder animations builder: (_ index: Int) -> [AnimatesSimultaneously]
    ) {
        self.init(repeatCount: repeatCount, builder: builder)
    }
    
    /// Loop through a sequence of values, like objects in an array or a range of numbers
    /// - Parameters:
    ///   - sequence: Sequence to loop through, each element will be handled in the `animations` closure
    ///   - animations: Add each animation from within this closure. Animations added to this loop should conform to ``AnimatesSimultaneously``
    /// - Returns: Group of all animations created in the `animation` closure
    public static func through<S: Swift.Sequence>(
        _ sequence: S,
        @AnimationBuilder animations builder: (S.Element) -> [AnimatesSimultaneously]
    ) -> [AnimatesSimultaneously] {
        map(sequence, with: builder)
    }
}

extension Loop where Looped == AnimatesSimultaneously {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        Group(animations: animations).animate(delay: leadingDelay, completion: completion)
    }
}

extension Swift.Sequence {
    /// Maps values from the sequence to animations
    /// - Parameter animations: Add each animation from within this closure. Animations should conform to ``AnimatesSimultaneously``
    /// - Returns: Sequence of all animations created in the `animation` closure
    public func mapAnimations(
        @AnimationBuilder animations builder: (Element) -> [AnimatesInSequence]
    ) -> [AnimatesInSequence] {
        flatMap(builder)
    }
    
    /// Maps values from the sequence to animations
    /// - Parameter animations: Add each animation from within this closure. Animations added to this loop should conform to ``AnimatesSimultaneously``
    /// - Returns: Group of all animations created in the `animation` closure
    public func mapAnimations(
        @AnimationBuilder animations builder: (Element) -> [AnimatesSimultaneously]
    ) -> [AnimatesSimultaneously] {
        flatMap(builder)
    }
}
