//
//  Collections+Extension.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/17/21.
//

import Foundation

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise `nil`.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
