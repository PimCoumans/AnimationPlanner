import UIKit

public struct Loop<A> {
    public var duration: TimeInterval
    public let animations: [A]
}

extension Loop: SequenceAnimationConvertible where A == SequenceAnimates {
    public func asSequence() -> [SequenceAnimates] {
        animations
    }
    
    public init(
        _ repeatCount: Int,
        @AnimationBuilder<SequenceAnimates> builder: (_ index: Int) -> [SequenceAnimates]
    ) {
        animations = (0..<repeatCount).flatMap(builder)
        duration = animations.reduce(0, { $0 + $1.duration })
    }
    
    public static func through<Element>(
        array: Array<Element>,
        @AnimationBuilder<SequenceAnimates> builder: (Element) -> [SequenceAnimates]
    ) -> [SequenceAnimates] {
        array.flatMap(builder)
    }
}

extension Loop: GroupAnimationConvertible where A == GroupAnimates {
    public func asGroup() -> [GroupAnimates] {
        animations
    }
    
    public init(
        _ repeatCount: Int,
        @AnimationBuilder<SequenceAnimates> builder: (_ index: Int) -> [GroupAnimates]
    ) { 
        animations = (0..<repeatCount).flatMap(builder)
        duration = animations.max(by: { $0.totalDuration < $1.totalDuration }).map(\.totalDuration) ?? 0
    }
    public static func through<Element>(
        array: Array<Element>,
        @AnimationBuilder<GroupAnimates> builder: (Element) -> [GroupAnimates]
    ) -> [GroupAnimates] {
        array.flatMap(builder)
    }
}
