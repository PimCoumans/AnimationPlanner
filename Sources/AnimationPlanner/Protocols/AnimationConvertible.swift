/// Provides a way to create a uniform sequence from all animations conforming to ``SequenceAnimatable``
public protocol SequenceConvertible {
    func asSequence() -> [SequenceAnimatable]
}

/// Provides a way to group together animations conforming to ``GroupAnimatable``
public protocol GroupConvertible {
    func asGroup() -> [GroupAnimatable]
}

extension Array: SequenceConvertible where Element == SequenceAnimatable {
    public func asSequence() -> [SequenceAnimatable] { flatMap { $0.asSequence() } }
}

extension Array: GroupConvertible where Element == GroupAnimatable {
    public func asGroup() -> [GroupAnimatable] { flatMap { $0.asGroup() } }
}
