//
//  CoreMotionProvider.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/17/21.
//

import Foundation
import CoreMotion
import RxCoreMotion
import RxSwift

// #if !targetEnvironment(simulator)
final class CoreMotionProvider: GyroscopMotionProvider {

    let manager: CMMotionManager

    init(manager: CMMotionManager, updateInterval timeInterval: TimeInterval) {
        self.manager = manager
        self.manager.gyroUpdateInterval = timeInterval
        self.manager.deviceMotionUpdateInterval = timeInterval
        self.manager.accelerometerUpdateInterval = timeInterval
    }

    func start() -> Single<Bool> {
        return isCoreMotionReadyToUse()
            .do {[weak manager] value  in
                guard value else {
                    return
                }

                manager?.startGyroUpdates()
                manager?.startAccelerometerUpdates()
                manager?.startDeviceMotionUpdates()

            }
            .asSingle()
    }

    func getRotatingData() -> Observable<GyroscopeData> {
        return isCoreMotionReadyToUse()
            .filter { $0 }
            .flatMapLatest {[weak manager] _ -> Observable<CMRotationRate> in
                return manager?.rx.rotationRate ?? .never()
            }
            .map {
                log.debug("\($0)")
                return GyroscopeData()
            }
    }

    func stop() -> Single<Bool> {
        return isCoreMotionReadyToUse()
            .do {[weak manager] value  in
                guard value else {
                    return
                }

                manager?.stopGyroUpdates()
                manager?.stopAccelerometerUpdates()
                manager?.stopDeviceMotionUpdates()

            }
            .asSingle()
    }

    private func isCoreMotionReadyToUse() -> Observable <Bool> {

        guard manager.isGyroActive && manager.isGyroAvailable else {
            return .just(false)
        }

        guard manager.isAccelerometerActive && manager.isAccelerometerAvailable else {
            return .just(false)
        }

        guard manager.isDeviceMotionActive && manager.isDeviceMotionAvailable else {
            return .just(false )
        }

        return .just(true)
    }

}

// #endif
