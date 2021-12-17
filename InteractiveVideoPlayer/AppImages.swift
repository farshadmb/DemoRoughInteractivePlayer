//
//  AppImages.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/16/21.
//

import Foundation
import UIKit

extension UIImage {

    enum Images: String, ImageAssets {
        case placeHolder
    }

    enum Icon: String, ImageAssets {
        case none
    }

    @available(iOS 13.0, *)
    enum Symbols: String, ImageAssets {

        case play = "play.circle.fill"
        case pause = "pause.circle.fill"
        case backward = "gobackward.15"
        case forward = "goforward.15"
        case stop = "stop.fill"
        case reset = "gobackward"

        var isSymbol: Bool {
            true
        }

        var image: UIImage {
           templateImage
        }
    }
}
