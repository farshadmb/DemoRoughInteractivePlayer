//
//  UIView+Nib.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/16/21.
//

import Foundation
import UIKit

extension UIView {

    /**
     Load and Instantiate the view from nib.
     */
    class func fromNib(nibNameOrNil: String? = nil) -> Self {
        return fromNib(nibNameOrNil: nibNameOrNil, type: self)
    }

    /**
     Load and Instantiate the view from nib where `T` is `UIView`.
     This apporch is generic and reduce code doublication.

     - Parameters:
        - nibNameOrNil: the nib name value that view is loaded from.
        - type: The `T.Type` value determind the class reflection.
     - Returns: The determined instance that is subclass of `UIView`.
     */
    class func fromNib<T: UIView>(nibNameOrNil: String? = nil, type: T.Type) -> T {
        let view: T? = fromNib(nibNameOrNil: nibNameOrNil, type: T.self)
        // swiftlint:disable:next force_unwrapping
        return view!
    }

    /**
     Load and Instantiate the view from nib where `T` is `UIView`. if found a suitable nib file.
     This apporch is generic and reduce code doublication.

     - Parameters:
        - nibNameOrNil: the nib name value that view is loaded from.
        - type: The `T.Type` value determind the class reflection.
     - Returns: The determined optional instance that is subclass of `UIView`.
     */
    class func fromNib<T: UIView>(nibNameOrNil: String? = nil, type: T.Type) -> T? {
        var view: T?
        let name: String
        if let nibName = nibNameOrNil {
            name = nibName
        } else {
            // Most nibs are demangled by practice, if not, just declare string explicitly
            name = String(describing: T.self)
        }

        let nibViews = Bundle.main.loadNibNamed(name, owner: nil, options: nil)

        nibViews?.forEach({ (nibView) in
            if let tog = nibView as? T {
                view = tog
            }
        })

        return view
    }

}

extension UIView {

    /**
     The `UINib` instance.
     */
    class var nib: UINib {
        Self.nib()
    }

    /**
     Create and Return `UINib` for `UIView` subclass type.
     */
    class func nib(nibNameOrNil: String? = nil) -> UINib {
        return nib(nibNameOrNil: nibNameOrNil, type: self)
    }

    /**
     Create and Return `UINib` for `UIView` subclass type.
     - Parameters:
        - nibNameOrNil: the nib name value that view is loaded from.
        - type: The `T.Type` value determind the `UIView` subclass reflection.
     - Returns: `UINib` object for `UIView` subclass type.
     */
    class func nib<T: UIView>(nibNameOrNil: String? = nil, type: T.Type) -> UINib {

        let name: String

        if let nibName = nibNameOrNil {
            name = nibName
        } else {
            // Most nibs are demangled by practice, if not, just declare string explicitly
            name = String(describing: type)
        }

        let bundle = Bundle(for: type)

        return UINib(nibName: name, bundle: bundle)
    }
}

#if swift(>=5.1)
/**
 Property wrapper used to wrapp a view instanciated from a Nib
 */
@propertyWrapper
@dynamicMemberLookup
final class NibWrapper<T: UIView> {

    /**
     Initializer
     */
    init() {
        wrappedValue = T.fromNib()
    }

    /// The wrapped value
    private(set) var wrappedValue: T

    /// The final view
    var unwrapped: T {
        wrappedValue
    }

    /**
     Dynamic member lookup to transfer keypath to the final view
     */
    subscript<U>(dynamicMember keyPath: KeyPath<T,U>) -> U {
        unwrapped[keyPath: keyPath]
    }

    /**
     Dynamic member lookup to transfer writable keypath to the final view
     */
    subscript<U>(dynamicMember keyPath: WritableKeyPath<T,U>) -> U {
        get { unwrapped[keyPath: keyPath] }
        set {
            var unwrappedView = unwrapped
            unwrappedView[keyPath: keyPath] = newValue
        }
    }
}
#endif
