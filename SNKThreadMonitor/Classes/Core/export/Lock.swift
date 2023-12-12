//
//  Lock.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/8/23.
//

import Foundation

public protocol Lock {
    func lock()
    func unlock()
}

public extension Lock {
    func around<T>(_ closure: () -> T) -> T {
        lock(); defer { unlock() }
        return closure()
    }
    func around(_ closure: () -> Void) {
        lock(); defer { unlock() }
        closure()
    }
}

#if os(Linux) || os(Windows)

extension NSLock: Lock {}

#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
final public class UnfairLock: Lock {
    private let unfairLock: os_unfair_lock_t

    init() {
        unfairLock = .allocate(capacity: 1)
        unfairLock.initialize(to: os_unfair_lock())
    }

    deinit {
        unfairLock.deinitialize(count: 1)
        unfairLock.deallocate()
    }

    public func lock() {
        os_unfair_lock_lock(unfairLock)
    }

    public func unlock() {
        os_unfair_lock_unlock(unfairLock)
    }
}
#endif

@propertyWrapper
@dynamicMemberLookup
public final class Protected<T> {
    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    private let lock = UnfairLock()
    #elseif os(Linux) || os(Windows)
    private let lock = NSLock()
    #endif
    private var value: T

    public init(_ value: T) {
        self.value = value
    }
    public var wrappedValue: T {
        get { lock.around { value } }
        set { lock.around { value = newValue } }
    }

    public var projectedValue: Protected<T> { self }

    public init(wrappedValue: T) {
        value = wrappedValue
    }
    public func read<U>(_ closure: (T) -> U) -> U {
        lock.around { closure(self.value) }
    }
    @discardableResult
    public func write<U>(_ closure: (inout T) -> U) -> U {
        lock.around { closure(&self.value) }
    }

    public subscript<Property>(dynamicMember keyPath: WritableKeyPath<T, Property>) -> Property {
        get { lock.around { value[keyPath: keyPath] } }
        set { lock.around { value[keyPath: keyPath] = newValue } }
    }
}

public extension Protected where T: RangeReplaceableCollection {
    func append(_ newElement: T.Element) {
        write { (ward: inout T) in
            ward.append(newElement)
        }
    }
    func append<S: Sequence>(contentsOf newElements: S) where S.Element == T.Element {
        write { (ward: inout T) in
            ward.append(contentsOf: newElements)
        }
    }
    func append<C: Collection>(contentsOf newElements: C) where C.Element == T.Element {
        write { (ward: inout T) in
            ward.append(contentsOf: newElements)
        }
    }
}

public extension Protected where T == Data? {
    func append(_ data: Data) {
        write { (ward: inout T) in
            ward?.append(data)
        }
    }
}

