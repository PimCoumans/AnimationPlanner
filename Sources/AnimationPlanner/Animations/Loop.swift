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
}

extension Loop: SequenceAnimatesConvertible where Looped == AnimatesInSequence {
    public func asSequence() -> [AnimatesInSequence] {
        animations
    }
    
    public init(
        for repeatCount: Int,
        @AnimationBuilder animations builder: (_ index: Int) -> [AnimatesInSequence]
    ) {
        animations = (0..<repeatCount).flatMap(builder)
        duration = animations.reduce(0, { $0 + $1.duration })
    }
    
    public static func through<S: Swift.Sequence>(
        _ sequence: S,
        @AnimationBuilder animations builder: (S.Element) -> [AnimatesInSequence]
    ) -> [AnimatesInSequence] {
        sequence.flatMap(builder)
    }
}

extension Loop: SimultaneouslyAnimatesConvertible where Looped == AnimatesSimultaneously {
    public func asGroup() -> [AnimatesSimultaneously] {
        animations
    }
    
    public init(
        for repeatCount: Int,
        @AnimationBuilder animations builder: (_ index: Int) -> [AnimatesSimultaneously]
    ) {
        animations = (0..<repeatCount).flatMap(builder)
        duration = animations.max(by: { $0.totalDuration < $1.totalDuration }).map(\.totalDuration) ?? 0
    }
    
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
