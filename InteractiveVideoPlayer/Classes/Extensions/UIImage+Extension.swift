//
//  UIImage+Extension.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/16/21.
//

import Foundation
import UIKit

/// The
protocol OptionalImage {

}

extension UIImage: OptionalImage {

}

extension Optional where Wrapped: OptionalImage {

    /**
     The `Bool` value indicate the image is Empty or not.
     */
    var isEmpty: Bool {
        return UIImage.isEmpty(self as? UIImage)
    }

}

/// UIImageContentMode Enum. The definition is simular to `UIView.ContentMode`
enum UIImageContentMode {
    case scaleToFill, scaleAspectFit, scaleAspectFill
}

extension UIImage {

    /**
     The `Bool` value indicate the image is Empty or not.
     */
    var isEmpty: Bool {
        size == .zero || bytesSize == 0
    }

    /**
     Determide the given Image isEmpty or not
     - Parameter aImage: an optional `UIImage` value.
     - Returns: `Bool` value that might be `true` when image is Empty, otherwise return `false`.
     */
    static func isEmpty(_ aImage: UIImage?) -> Bool {

        guard let image = aImage else {
            return true
        }

        return image.isEmpty
    }

    /**
     Resize image to given size and contentMode
     - Parameters:
        - toSize: the `Size` value
        - contentMode: The `UIImageConentMode` value. default is `UIImageContentMode.scaleToFill`.
     - Returns: The optional resized `UIImage` instance.
     */
    func resize(toSize: CGSize, contentMode: UIImageContentMode = .scaleToFill) -> UIImage? {
        let horizontalRatio = size.width / self.size.width
        let verticalRatio = size.height / self.size.height
        var ratio: CGFloat!

        switch contentMode {
        case .scaleToFill:
            ratio = 1
        case .scaleAspectFill:
            ratio = max(horizontalRatio, verticalRatio)
        case .scaleAspectFit:
            ratio = min(horizontalRatio, verticalRatio)
        }

        let rect = CGRect(x: 0, y: 0, width: size.width * ratio, height: size.height * ratio)

        // Fix for a colorspace / transparency issue that affects some types of
        // images. See here: http://vocaro.com/trevor/blog/2009/10/12/resize-a-uiimage-the-right-way/comment-page-2/#comment-39951

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(data: nil, width: Int(rect.size.width), height: Int(rect.size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }

        let transform = CGAffineTransform.identity

        // Rotate and/or flip the image if required by its orientation
        context.concatenate(transform)

        // Set the quality level to use when rescaling
        context.interpolationQuality = CGInterpolationQuality(rawValue: 3) ?? .default

        // CGContextSetInterpolationQuality(context, CGInterpolationQuality(kCGInterpolationHigh.value))

        // Draw into the context; this scales the image
        // swiftlint:disable force_unwrapping
        context.draw(self.cgImage!, in: rect)

        // Get the resized image from the context and a UIImage
        // swiftlint:disable force_unwrapping
        let newImage = UIImage(cgImage: context.makeImage()!,
                               scale: self.scale,
                               orientation: self.imageOrientation)
        return newImage
    }

}

extension UIImage {

    ///  Returns base64 string
    var base64: String {
        return jpegData(compressionQuality: 1.0)!.base64EncodedString()
    }

    /**
     Returns Image size in Bytes
     - Returns: the size of image in Bytes
     */
    func getSizeAsBytes() -> Int {
        return jpegData(compressionQuality: 1.0)?.count ?? 0
    }

    /**
     Returns Image size in Kylobites
     - Returns: the size of image in Kilo Bytes
     */
    func getSizeAsKilobytes() -> Int {
        let sizeAsBytes = getSizeAsBytes()
        return sizeAsBytes != 0 ? sizeAsBytes / 1024 : 0
    }

    /**
     Scales image to given width and height
     - Parameters:
        - image: the source image
        - w: the width size
        - h: the height size
     - Returns: return new `UIImage` instance that is scaled from source image
     */
    class func scaleTo(image: UIImage, w: CGFloat, h: CGFloat) -> UIImage {// swiftlint:disable:this identifier_name
        let newSize = CGSize(width: w, height: h)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

    /**
     Returns resized image with width. Might return low quality
     - Parameter width: resize image to given width size
     */
    func resizeWithWidth(_ width: CGFloat) -> UIImage {
        let aspectSize = CGSize(width: width, height: aspectHeightForWidth(width))

        UIGraphicsBeginImageContextWithOptions(aspectSize, false, UIScreen.main.scale)
        self.draw(in: CGRect(origin: CGPoint.zero, size: aspectSize))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return img!
    }

    /**
     Returns resized image with height. Might return low quality
     - Parameter height: the height value that image should resize to.
     */
    func resizeWithHeight(_ height: CGFloat) -> UIImage {
        let aspectSize = CGSize(width: aspectWidthForHeight(height), height: height)

        UIGraphicsBeginImageContextWithOptions(aspectSize, false, UIScreen.main.scale)
        self.draw(in: CGRect(origin: CGPoint.zero, size: aspectSize))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return img!
    }

    /**
     Calculate a new Height Aspect Ratio based on a given width size.
     - Parameter width: the `CGFloat` width size.
     - Returns: a new calculated `CGFloat` height size.
     */
    func aspectHeightForWidth(_ width: CGFloat) -> CGFloat {
        return (width * self.size.height) / self.size.width
    }

    /**
     Calculate a new Wdith Aspect Ratio based on a given height size.
     - Parameter height: the `CGFloat` height size.
     - Returns: a new calculated `CGFloat` width size.
     */
    func aspectWidthForHeight(_ height: CGFloat) -> CGFloat {
        return (height * self.size.width) / self.size.height
    }

    /**
     Use current image for pattern of color
     - Parameter tintColor: the pattern color
     */
    func withColor(_ tintColor: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)

        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(CGBlendMode.normal)

        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height) as CGRect
        context?.clip(to: rect, mask: self.cgImage!)
        tintColor.setFill()
        context?.fill(rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()! as UIImage
        UIGraphicsEndImageContext()

        return newImage
    }

    /// Returns the image associated with the URL
    /// - Parameter urlString: the `String` fileURL to load image from.
    convenience init?(urlString: String) {
        guard let url = URL(string: urlString) else {
            self.init(data: Data())
            return
        }
        guard let data = try? Data(contentsOf: url) else {
            self.init(data: Data())
            return
        }
        self.init(data: data)
    }

    /**
     Created and Return black image
     - Returns: blank image
     */
    class func blankImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 1), false, UIScreen.main.scale)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

extension UIImage {

    /// Size in bytes of UIImage
    var bytesSize: Int {
        getSizeAsBytes()
    }

    /// Size in kilo bytes of UIImage
    var kilobytesSize: Int {
        getSizeAsKilobytes()
    }

    /// UIImage with .alwaysOriginal rendering mode.
    var original: UIImage {
        withRenderingMode(.alwaysOriginal)
    }

    /// UIImage with .alwaysTemplate rendering mode.
    var template: UIImage {
        withRenderingMode(.alwaysTemplate)
    }

}

// MARK: - Methods
extension UIImage {

    /**
     Compressed UIImage from original UIImage.

     - Parameter quality: The quality of the resulting JPEG image,
                            expressed as a value from 0.0 to 1.0. The value 0.0 represents
                            the maximum compression (or lowest quality) while
                            the value 1.0 represents the least compression (or best quality), (default is 0.5).
     - Returns: optional UIImage (if applicable).
     */
    func compressed(quality: CGFloat = 0.5) -> UIImage? {
        guard let data = compressedData(quality: quality) else {
            return nil

        }

        return UIImage(data: data)
    }

    /**
     Compressed UIImage data from original UIImage.
     - Parameter quality: The quality of the resulting JPEG image, expressed as a value from 0.0 to 1.0.
                          The value 0.0 represents the maximum compression (or lowest quality) while
                          the value 1.0 represents the least compression (or best quality), (default is 0.5).
     - Returns: optional Data (if applicable).
     */
    func compressedData(quality: CGFloat = 0.5) -> Data? {
        return jpegData(compressionQuality: quality)
    }

    /**
     UIImage Cropped to CGRect.

        - Parameter rect: CGRect to crop UIImage to.
     - Returns: cropped UIImage
     */
    func cropped(to rect: CGRect) -> UIImage {
        guard rect.size.height < size.height && rect.size.height < size.height else {
            return self
        }
        guard let image: CGImage = cgImage?.cropping(to: rect) else {
            return self
        }
        return UIImage(cgImage: image)
    }

    /**
     UIImage scaled to height with respect to aspect ratio.

     - Parameters:
        - toHeight: new height.
        - orientation: optional UIImage orientation (default is nil).
     - Returns: optional scaled UIImage (if applicable).
     */
    func scaled(toHeight: CGFloat, with orientation: UIImage.Orientation? = nil) -> UIImage? {
        let scale = toHeight / size.height
        let newWidth = size.width * scale
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: toHeight), false, UIScreen.main.scale)
        //        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: toHeight))
        draw(in: CGRect(x: 0, y: 0, width: newWidth, height: toHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

    /**
     UIImage scaled to width with respect to aspect ratio.

     - Parameters:
        - toWidth: new width.
        - orientation: optional UIImage orientation (default is nil).
     - Returns: optional scaled UIImage (if applicable).
     */
    func scaled(toWidth: CGFloat, with orientation: UIImage.Orientation? = nil) -> UIImage? {
        let scale = toWidth / size.width
        let newHeight = size.height * scale

        UIGraphicsBeginImageContextWithOptions(CGSize(width: toWidth, height: newHeight), false, UIScreen.main.scale)
        draw(in: CGRect(x: 0, y: 0, width: toWidth, height: newHeight))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

    /**
     UIImage filled with color

     - Parameter color: color to fill image with.
     - Returns: UIImage filled with given color.
     */
    func filled(withColor color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        color.setFill()
        guard let context = UIGraphicsGetCurrentContext() else {
            return self
        }

        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(CGBlendMode.normal)

        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        guard let mask = self.cgImage else {
            return self
        }
        context.clip(to: rect, mask: mask)
        context.fill(rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

    /**
     UIImage tinted with color

     - Parameters:
        - color: color to tint image with.
        - blendMode: how to blend the tint
     - Returns: UIImage tinted with given color.
     */
    func tint(_ color: UIColor, blendMode: CGBlendMode) -> UIImage {
        let drawRect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()
        context!.clip(to: drawRect, mask: cgImage!)
        color.setFill()
        UIRectFill(drawRect)
        draw(in: drawRect, blendMode: blendMode, alpha: 1.0)
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage!
    }
}

// MARK: - Initializers
extension UIImage {

    /**
     Create UIImage from color and size.

     - Parameters:
        - color: image fill color.
        - size: image size.
     */
    convenience init(color: UIColor, size: CGSize) {

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        color.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            self.init()
            return
        }
        UIGraphicsEndImageContext()
        guard let aCgImage = image.cgImage else {
            self.init()
            return
        }
        self.init(cgImage: aCgImage)
    }

}
