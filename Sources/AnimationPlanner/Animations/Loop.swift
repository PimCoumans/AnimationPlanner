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
    public var duration: TimeInterval
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

extension Loop: SequenceAnimatesConvertible where Looped == AnimatesInSequence {
    public func asSequence() -> [AnimatesInSequence] {
        animations
    }
    
    public init(
        for repeatCount: Int,
        @AnimationBuilder animations builder: (_ index: Int) -> [AnimatesInSequence]
    ) {
    }
    
    public static func through<S: Swift.Sequence>(
        _ sequence: S,
        @AnimationBuilder animations builder: (S.Element) -> [AnimatesInSequence]
    ) -> [AnimatesInSequence] {
    }
}

extension Loop: SimultaneouslyAnimatesConvertible where Looped == AnimatesSimultaneously {
    public func asGroup() -> [AnimatesSimultaneously] {
        animations
    }
    
    /// Creates a new Loop that repeats for the given amount of times.
    /// - Parameters:
    ///   - repeatCount: How many times the loop should repeat. The index of each loop is provided as a argument in the `animations` closure
    public init(
        for repeatCount: Int,
        @AnimationBuilder animations builder: (_ index: Int) -> [AnimatesSimultaneously]
    ) {
        animations = (0..<repeatCount).flatMap(builder)
        duration = animations.max(by: { $0.totalDuration < $1.totalDuration }).map(\.totalDuration) ?? 0
    }
    
    /// - Parameters:
    ///   - sequence: Sequence to loop through, each element will be handled in the `animations` closure
    public static func through<S: Swift.Sequence>(
        _ sequence: S,
        @AnimationBuilder animations builder: (S.Element) -> [AnimatesSimultaneously]
    ) -> [AnimatesSimultaneously] {
        sequence.flatMap(builder)
    }
}

extension Swift.Sequence {
    public func mapAnimations(
        @AnimationBuilder animations builder: (Element) -> [AnimatesInSequence]
    ) -> [AnimatesInSequence] {
        flatMap(builder)
    }
    
    public func mapAnimations(
        @AnimationBuilder animations builder: (Element) -> [AnimatesSimultaneously]
    ) -> [AnimatesSimultaneously] {
        flatMap(builder)
    }
}
