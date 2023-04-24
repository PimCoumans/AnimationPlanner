import Foundation

extension Swift.Sequence {
    /// Maps values from the sequence to animations
    /// - Parameter animations: Add each animation from within this closure. Animations should conform to ``GroupAnimatable``
    /// - Returns: Sequence of all animations created in the `animation` closure
    public func mapSequence(
        @SequenceBuilder animations builder: (Element) -> [SequenceAnimatable]
    ) -> [SequenceAnimatable] {
        flatMap(builder)
    }

    /// Maps values from the sequence to animations
    /// - Parameter animations: Add each animation from within this closure. Animations added to this loop should conform to ``GroupAnimatable``
    /// - Returns: Group of all animations created in the `animation` closure
    public func mapGroup(
        @GroupBuilder animations builder: (Element) -> [GroupAnimatable]
    ) -> [GroupAnimatable] {
        flatMap(builder)
    }
}
