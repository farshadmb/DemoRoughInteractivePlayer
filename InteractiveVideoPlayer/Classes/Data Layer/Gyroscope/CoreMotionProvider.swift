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

    private let disposeBag = DisposeBag()

    init(manager: CMMotionManager, updateInterval timeInterval: TimeInterval) {
        self.manager = manager
        self.manager.gyroUpdateInterval = timeInterval
        self.manager.deviceMotionUpdateInterval = timeInterval
        self.manager.accelerometerUpdateInterval = timeInterval
    }

    func start() -> Single<Bool> {
        return isCoreMotionReadyToUse()
            .asSingle()
    }

    func getRotatingData() -> Observable<GyroscopeData> {
        return isCoreMotionReadyToUse()
            .filter { $0 }
            .flatMapLatest {[weak manager] _ -> Observable<CMDeviceMotion> in
                guard let manager = manager else {
                    return .never()
                }

                return manager.rx.deviceMotion
            }
            .compactMap({ $0 })
            .distinctUntilChanged()
            .map(GyroscopeData.init(motionData:))

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

        guard manager.isGyroAvailable else {
            log.error("CoreMotion Gyro is not Ready to use.")
            return .just(false)
        }

        guard manager.isAccelerometerAvailable else {
            log.error("CoreMotion Accelerometer is not Ready to use.")
            return .just(false)
        }

        guard manager.isDeviceMotionAvailable else {
            log.error("CoreMotion DeviceMotion is not Ready to use.")
            return .just(false )
        }

        log.debug("CoreMotion is Ready to use.")
        return .just(true)
    }

}

fileprivate extension GyroscopeData {

    init(motionData: CMDeviceMotion) {
//        log.debug("motionData atitudes \(motionData.attitude)")
        log.debug("motionData rotating \(motionData.rotationRate)")
//        log.debug("motionData rotating \(motionData.attitude.rotationMatrix)")
        self.zRotating = atan2(motionData.gravity.x, motionData.gravity.y) - .pi
        self.xRotating = atan2(motionData.gravity.z, motionData.gravity.y) - .pi
    }

}

// #endif
