//
//  FakeGyroscopMotionProvider.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/17/21.
//

import Foundation
import CoreMotion
import RxSwift
import RxCocoa

struct FakeGyroscopMotionProvider: GyroscopMotionProvider {

    let cancelObs = PublishSubject<Void>()
    let timeInterval: Int

    init(timeInterval: Int) {
        self.timeInterval = timeInterval
    }

    func start() -> Single<Bool> {
        return .just(true)
    }

    func getRotatingData() -> Observable<GyroscopeData> {
        let data = CMRotationRate(x: 0, y: 0, z: 0)
        let countdown = 20

        return Observable<Int>.interval(.seconds(timeInterval), scheduler: MainScheduler.instance)
            .map { countdown - $0 }
            .take(until: cancelObs)
            .take(while: { $0 == 0 }, behavior: .inclusive)
            .map({ _ in GyroscopeData() })
            .do(onNext: { _ in
                print(data)
            })
    }

    func stop() -> Single<Bool> {
        cancelObs.onNext(())
        return .just(true)
    }

}
