//
//  AtomicWrapper.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/16/21.
//

import Foundation

#if swift(>=5.1)
@propertyWrapper
final class Atomic<Value> {

    private var value: Value
    private let lock = UnfairLock()

    init(wrappedValue value: Value) {
        self.value = value
    }

    var wrappedValue: Value {
      get { return load() }
      set { store(newValue: newValue) }
    }

    func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func store(newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}
#endif

final class UnfairLock {

    private var _lock = os_unfair_lock()

    func lock() { os_unfair_lock_lock(&_lock) }
    func locked() -> Bool { return os_unfair_lock_trylock(&_lock) }
    func unlock() { os_unfair_lock_unlock(&_lock) }
}
