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
        
        if Looped.self == SequenceAnimatable.self, let animations = animations as? [SequenceAnimatable] {
            duration = animations.reduce(0, { $0 + $1.duration })
        } else if Looped.self == GroupAnimatable.self, let animations = animations as? [GroupAnimatable] {
            duration = animations.max(by: { $0.duration < $1.duration }).map(\.duration) ?? 0
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

extension Loop: SequenceConvertible where Looped == SequenceAnimatable {
    
    public func asSequence() -> [SequenceAnimatable] {
        animations
    }
    
    /// Creates a new Loop that repeats for the given amount of times.
    /// - Parameters:
    ///   - repeatCount: How many times the loop should repeat. The index of each loop is provided as a argument in the `animations` closure
    ///   - animations: Add each animation from within this closure. Animations added to this loop should conform to ``SequenceAnimatable``
    public init(
        for repeatCount: Int,
        @AnimationBuilder animations builder: (_ index: Int) -> [SequenceAnimatable]
    ) {
        self.init(repeatCount: repeatCount, builder: builder)
    }
    
    /// Loop through a sequence of values, like objects in an array or a range of numbers
    /// - Parameters:
    ///   - sequence: Sequence to loop through, each element will be handled in the `animations` closure
    ///   - animations: Add each animation from within this closure. Animations added to this loop should conform to ``SequenceAnimatable``
    /// - Returns: Sequence of all animations created in the `animation` closure
    public static func through<S: Swift.Sequence>(
        _ sequence: S,
        @AnimationBuilder animations builder: (S.Element) -> [SequenceAnimatable]
    ) -> [SequenceAnimatable] {
        map(sequence, with: builder)
    }
}

extension Loop: GroupConvertible where Looped == GroupAnimatable {
    
    public func asGroup() -> [GroupAnimatable] {
        animations
    }
    
    /// Creates a new Loop that repeats for the given amount of times.
    /// - Parameters:
    ///   - repeatCount: How many times the loop should repeat. The index of each loop is provided as a argument in the `animations` closure
    ///   - animations: Add each animation from within this closure. Animations added to this loop should conform to ``GroupAnimatable``
    public init(
        for repeatCount: Int,
        @AnimationBuilder animations builder: (_ index: Int) -> [GroupAnimatable]
    ) {
        self.init(repeatCount: repeatCount, builder: builder)
    }
    
    /// Loop through a sequence of values, like objects in an array or a range of numbers
    /// - Parameters:
    ///   - sequence: Sequence to loop through, each element will be handled in the `animations` closure
    ///   - animations: Add each animation from within this closure. Animations added to this loop should conform to ``GroupAnimatable``
    /// - Returns: Group of all animations created in the `animation` closure
    public static func through<S: Swift.Sequence>(
        _ sequence: S,
        @AnimationBuilder animations builder: (S.Element) -> [GroupAnimatable]
    ) -> [GroupAnimatable] {
        map(sequence, with: builder)
    }
}

extension Loop where Looped == GroupAnimatable {
    public func animate(delay leadingDelay: TimeInterval, completion: ((Bool) -> Void)?) {
        Group(animations: animations).animate(delay: leadingDelay, completion: completion)
    }
}

extension Swift.Sequence {
    /// Maps values from the sequence to animations
    /// - Parameter animations: Add each animation from within this closure. Animations should conform to ``GroupAnimatable``
    /// - Returns: Sequence of all animations created in the `animation` closure
    public func mapAnimations(
        @AnimationBuilder animations builder: (Element) -> [SequenceAnimatable]
    ) -> [SequenceAnimatable] {
        flatMap(builder)
    }
    
    /// Maps values from the sequence to animations
    /// - Parameter animations: Add each animation from within this closure. Animations added to this loop should conform to ``GroupAnimatable``
    /// - Returns: Group of all animations created in the `animation` closure
    public func mapAnimations(
        @AnimationBuilder animations builder: (Element) -> [GroupAnimatable]
    ) -> [GroupAnimatable] {
        flatMap(builder)
    }
}
