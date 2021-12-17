//
//  LateInit.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/16/21.
//

import Foundation

/**
 A property wrapper which lets you left a stored property uninitialized during construction and set its value later.

 In Swift *classes and structures must set all of their stored properties to an appropriate initial value by the time
 an instance of that class or structure is created. Stored properties cannot be left in an indeterminate state. *.

 LateInit lets you work around this restriction and leave a stored properties uninitialized. This also means you are
 responsible of initializing the property before it is accessed. Failing to do so will result in a fatal error.
 Sounds familiar? LateInit is an reimplementation of a Swift "Implicitly Unwrapped Optional".

 Usage:
 ```
 @LateInit var text: String

 // Note: Access before initialization triggers a fatal error:
 // print(text) // -> fatalError("Trying to access LateInit.value before setting it.")

 // Initialize later in your code:
 text = "Hello, World!"
 */
@propertyWrapper
struct LateInit<Value> {

    private var storage: Value?

    init() {

    }

    public var wrappedValue: Value {
        get {
            guard let storage = storage else {
                preconditionFailure("Trying to access LateInit.value before setting it.")
            }
            return storage
        }
        set {
            storage = newValue
        }
    }

    var projectedValue: Value? {
        return storage
    }

}

/**
 A property wrapper which lets you left a stored property uninitialized during construction and set its value later.

 In Swift *classes and structures must set all of their stored properties to an appropriate initial value by the time
 an instance of that class or structure is created. Stored properties cannot be left in an indeterminate state. *.

 AtomicLateInit lets you work around this restriction and leave a stored properties uninitialized. This also means you are
 responsible of initializing the property before it is accessed. Failing to do so will result in a fatal error.
 Sounds familiar? AtomicLateInit is an reimplementation of a Swift "Implicitly Unwrapped Optional".

 Usage:
 ```
 @AtomicLateInit var text: String

 // Note: Access before initialization triggers a fatal error:
 // print(text) // -> fatalError("Trying to access LateInit.value before setting it.")

 // Initialize later in your code:
 text = "Hello, World!"
 */
@propertyWrapper
final class AtomicLateInit<Value> {

    private var value: Value?
    private let lock = UnfairLock()

    init() {
        self.value = nil
    }

    init(wrappedValue value: Value) {
        self.value = value
    }

    var wrappedValue: Value {
        get {

            guard let storage = load() else {
                preconditionFailure("Trying to access LateInit.value before setting it.")
            }

            return storage
        }

        set { store(newValue: newValue) }
    }

    func load() -> Value? {
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
