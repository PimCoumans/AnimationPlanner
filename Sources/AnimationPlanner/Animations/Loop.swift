import UIKit

public struct Loop<A> {
    public var duration: TimeInterval
    public let animations: [A]
}

extension Loop: SequenceAnimatesConvertible where A == AnimatesInSequence {
    public func asSequence() -> [AnimatesInSequence] {
        animations
    }
    
    public init(
        for repeatCount: Int,
        @AnimationBuilder builder: (_ index: Int) -> [AnimatesInSequence]
    ) {
        animations = (0..<repeatCount).flatMap(builder)
        duration = animations.reduce(0, { $0 + $1.duration })
    }
    
    public static func through<S: Swift.Sequence>(
        _ sequence: S,
        @AnimationBuilder builder: (S.Element) -> [AnimatesInSequence]
    ) -> [AnimatesInSequence] {
        sequence.flatMap(builder)
    }
}

extension Loop: SimultaneouslyAnimatesConvertible where A == AnimatesSimultaneously {
    public func asGroup() -> [AnimatesSimultaneously] {
        animations
    }
    
    public init(
        for repeatCount: Int,
        @AnimationBuilder builder: (_ index: Int) -> [AnimatesSimultaneously]
    ) {
        animations = (0..<repeatCount).flatMap(builder)
        duration = animations.max(by: { $0.totalDuration < $1.totalDuration }).map(\.totalDuration) ?? 0
    }
    
    public static func through<S: Swift.Sequence>(
        _ sequence: S,
        @AnimationBuilder builder: (S.Element) -> [AnimatesSimultaneously]
    ) -> [AnimatesSimultaneously] {
        sequence.flatMap(builder)
    }
}

extension Swift.Sequence {
    public func mapAnimations(
        @AnimationBuilder builder: (Element) -> [AnimatesInSequence]
    ) -> [AnimatesInSequence] {
        flatMap(builder)
    }
    
    public func mapAnimations(
        @AnimationBuilder builder: (Element) -> [AnimatesSimultaneously]
    ) -> [AnimatesSimultaneously] {
        flatMap(builder)
    }
}
