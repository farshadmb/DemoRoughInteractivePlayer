//
//  GyroscopMotionProvider.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/17/21.
//

import Foundation
import RxSwift

protocol GyroscopMotionProvider {

    func start() -> Single<Bool>

    func getRotatingData() -> Observable<GyroscopeData>

    func stop() -> Single<Bool>
}
