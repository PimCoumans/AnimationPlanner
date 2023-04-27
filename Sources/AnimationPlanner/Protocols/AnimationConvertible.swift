/// Provides a way to create a uniform sequence from all animations conforming to ``SequenceAnimatable``
public protocol SequenceConvertible {
    func animations() -> [SequenceAnimatable]
}
extension SequenceConvertible where Self: SequenceAnimatable {
    public func animations() -> [SequenceAnimatable] {
        [self]
    }
}

/// Provides a way to group together animations conforming to ``GroupAnimatable``
public protocol GroupConvertible {
    func animations() -> [GroupAnimatable]
}
extension GroupConvertible where Self: GroupAnimatable {
    public func animations() -> [GroupAnimatable] {
        [self]
    }
}

extension Array: SequenceConvertible where Element == SequenceAnimatable {
    public func animations() -> [SequenceAnimatable] { flatMap { $0.animations() } }
}

extension Array: GroupConvertible where Element == GroupAnimatable {
    public func animations() -> [GroupAnimatable] { flatMap { $0.animations() } }
}
