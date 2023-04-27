import Foundation

@available(
    *, unavailable,
     message: "Loop convenience struct has been removed following type checking changes in Swift 5.8. Use a for-loops or the sequence extension method `mapSequence()` or `mapGroup()` instead"
)
/// Loop through a sequence or for a specified repeat count to easily repeat multiple animation.
/// - Warning: This struct is no longer available. The same functionality can be achieved by using `for`-loop or the methods `mapSequence()` and `mapGroup()` on any Swift Sequence.
public struct Loop: SequenceAnimatable, GroupAnimatable {
    public var duration: TimeInterval = 0
    public init(
        for repeatCount: Int,
        @SequenceBuilder animations builder: (_ index: Int) -> [SequenceAnimatable]
    ) { }

    public static func through<S: Swift.Sequence>(
        _ sequence: S,
        @SequenceBuilder animations builder: (S.Element) -> [SequenceAnimatable]
    ) -> [SequenceAnimatable] {
        []
    }

    public static func through<S: Swift.Sequence>(
        _ sequence: S,
        @SequenceBuilder animations builder: (S.Element) -> [GroupAnimatable]
    ) -> [GroupAnimatable] {
        []
    }
}
