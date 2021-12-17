//
//  FakeGPSLocationProvider.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/17/21.
//

import Foundation
import RxSwift
import CoreLocation

#if targetEnvironment(simulator)
final class FakeGPSLocationProvider: LocationProvider {

    let cancelObs = PublishSubject<Void>()
    let timeInterval: Int

    init(timeInterval: Int) {
        self.timeInterval = timeInterval
    }

    func startObservation() -> Observable<Result<Bool, Error>> {
        return .just(Result { true })
    }

    func getCurrentLocation() -> Observable<CLLocationCoordinate2D> {
        let currentLocation = CLLocationCoordinate2D(latitude: 40.1872, longitude: 44.5152)
        let countdown = 20

        return Observable<Int>.interval(.seconds(timeInterval), scheduler: MainScheduler.instance)
            .map { countdown - $0 }
            .take(until: cancelObs)
            .take(while: { $0 == 0 }, behavior: .inclusive)
            .compactMap {[weak self] (value) -> CLLocationCoordinate2D? in
                self?.locationWithBearing(bearingRadians: 0, distanceMeters: Double(value * 10), origin: currentLocation)
            }
    }

    func cancel() -> Observable<Bool> {
        cancelObs.onNext(())
        return .just(true)
    }

    private func locationWithBearing(bearingRadians: Double, distanceMeters: Double, origin: CLLocationCoordinate2D) -> CLLocationCoordinate2D {

        let distRadians = distanceMeters / (6_372_797.6) // earth radius in meters

        let lat1 = origin.latitude * Double.pi / 180
        let lon1 = origin.longitude * Double.pi / 180

        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearingRadians))
        let lon2 = lon1 + atan2(sin(bearingRadians) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))

        return CLLocationCoordinate2D(latitude: lat2 * 180 / Double.pi, longitude: lon2 * 180 / Double.pi)
    }

}
#endif
