//
//  ImageAssets.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/16/21.
//

import Foundation
import UIKit

/**
 ImagesAssets Protocol. this purpose aim to reduce code dublication and increase reuasble
 */
protocol ImageAssets {

    /**
     The Raw Image Name in Assets.xcassets.
     */
    var rawValue: String { get }

    /**
     The Default Image value.
     */
    var image: UIImage { get }

    /**
     The Template Rendered Image to work with `UIView.tintColor`
     */
    var templateImage: UIImage { get }

    /**
     The Original Rendered Image.
     */
    var originalImage: UIImage { get }

    /**
     The `Bool` value determin the value is Symbol or not.
     */
    var isSymbol: Bool { get }

}

/**
 The Default Impelemation for `ImageAssets`.
 */
extension ImageAssets {

    // :nodoc:
    var isSymbol: Bool {
        false
    }

    // :nodoc:
    var image: UIImage {
        UIImage.loadImage(named: self.rawValue, isSymbol: isSymbol)
    }

    // :nodoc:
    var templateImage: UIImage {
        let image = UIImage.loadImage(named: self.rawValue, isSymbol: isSymbol)
        return image.withRenderingMode(.alwaysTemplate)
    }

    // :nodoc:
    var originalImage: UIImage {
        let image = UIImage.loadImage(named: self.rawValue, isSymbol: isSymbol)
        return image.withRenderingMode(.alwaysOriginal)
    }

}

/**
 Image Loader Extensions for `UIImage`.
 */
private extension UIImage {

    /**
     Loaed Image with the given imageName.
     Added isSymbol parameter to support symbol image set
     - Parameters:
      - imageName: imageName to be loaded.
      - isSymbol: The `Bool`value indicate the `imageName` is symbol or not, default is `false`.
      - Returns: The `UIImage` object that would be loaded from Assets.xcassets.
      - Note: **When ImageNamed not found, this method raise `assertionFailure`.
     - Returns: The `UIImage` object which is loaded.
     */
    static func loadImage(named imageName: String, isSymbol: Bool = false) -> UIImage {
        let uiImage: UIImage?

        if #available(iOS 13.0, *), isSymbol {
            uiImage = UIImage(systemName: imageName)
        }else {
            uiImage = UIImage(named: imageName)
        }

        guard let image = uiImage else {
            let failureMessage = "\(imageName) " + (isSymbol ? "is not found in SFSymbols" :  "image missing from asset catalogue")
            assertionFailure(failureMessage)
            return UIImage()
        }

        return image
    }

    /**
     1 of 5 random line background varieties at a random orientation
     */
    static var lineBackground: UIImage {
        let index = Int.random(in: 1...5)
        let orientations: [UIImage.Orientation] = [.up, .down, .upMirrored, .downMirrored]
        guard let cgImage = UIImage.loadImage(named: "lineBackground\(index)").cgImage,
              let orientation = orientations.randomElement() else { return UIImage() }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation).withRenderingMode(.alwaysTemplate)
    }

}

extension UIImage: ImageAssets {

    var rawValue: String {
        ""
    }

    var image: UIImage {
        self
    }

    var templateImage: UIImage {
        template
    }

    var originalImage: UIImage {
        original
    }
}
