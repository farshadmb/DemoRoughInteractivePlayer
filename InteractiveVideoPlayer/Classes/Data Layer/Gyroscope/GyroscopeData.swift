//
//  GyroscopeData.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/17/21.
//

import Foundation

struct GyroscopeData {

    let zRotating: Double
    let xRotating: Double

    init() {
        zRotating = 0
        xRotating = 0
    }

    init(zRotating: Double, xRotating: Double) {
        self.zRotating = zRotating
        self.xRotating = xRotating
    }

}
