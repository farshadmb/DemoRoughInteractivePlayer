//
//  GPSLocationProvider.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/17/21.
//

import Foundation
import RxSwift
import CoreLocation
import RxCoreLocation

final class GPSLocationProvider: LocationProvider {

    let locationManager: CLLocationManager

    private var currentLocation: Observable<CLLocation> {
        return locationManager.rx.location.compactMap({ $0 })
    }

    let disposeBag = DisposeBag()

    init() {
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.activityType = .other
        locationManager.distanceFilter = 12

        locationManager.rx.didError.subscribe().disposed(by: disposeBag)
    }

    func startObservation() -> Observable<Result<Bool, Error>> {
        return getPermission()
            .flatMapLatest {[weak self] (status) -> Observable<Result<Bool, Error>> in
                guard let `self` = self, status == .authorizedWhenInUse else {
                    return .just(Result { false })
                }

                self.locationManager.startUpdatingLocation()
                return .just(Result { true })
            }
            .catch { (error) -> Observable<Result<Bool, Error>> in
                return .just(Result { throw error })
            }
    }

    func getCurrentLocation() -> Observable<CLLocationCoordinate2D> {
        let source = locationManager.rx.status
            .flatMapLatest {[weak self] (status) -> Observable<CLLocation> in
                guard let `self` = self, status == .authorizedWhenInUse else {
                    return .just(CLLocation(latitude: kCLLocationCoordinate2DInvalid.latitude,
                                            longitude: kCLLocationCoordinate2DInvalid.longitude))
                }

                self.locationManager.startUpdatingLocation()
                return self.currentLocation
            }
            .startWith(CLLocation(latitude: kCLLocationCoordinate2DInvalid.latitude,
                                  longitude: kCLLocationCoordinate2DInvalid.longitude))
            .scan(CLLocation(), accumulator: { (newLocation, oldLocation) -> CLLocation in
                log.debug("Scan compare with old \(oldLocation) with new \(newLocation)")
                let isLess10meters = abs(oldLocation.distance(from: newLocation)) < 10.0
                return isLess10meters ? oldLocation : newLocation
            })
            .distinctUntilChanged()
            .map { $0.coordinate }
            .distinctUntilChanged()
            .filter({ $0.isValid })
            .share(replay: 1, scope: .whileConnected)

        return source
    }

    func cancel() -> Observable<Bool> {
        locationManager.stopUpdatingLocation()
        return .just(true)
    }

    func getPermission() -> Observable<CLAuthorizationStatus> {
        return .create {[weak self] observer in

            guard let strSelf = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            let errorObserver = strSelf.locationManager.rx.didError
                .compactMap { $0.error }
                .bind { observer.onError($0) }

            strSelf.locationManager.requestWhenInUseAuthorization()

            let statusObserver = strSelf.locationManager.rx.status.filter { $0 != .notDetermined }
                .bind(to: observer)

            return Disposables.create([errorObserver, statusObserver])
        }
    }

}

extension CLLocationCoordinate2D: Equatable {

    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return fabs(lhs.latitude - rhs.latitude) <= Double.ulpOfOne && fabs(lhs.longitude - rhs.longitude) <= Double.ulpOfOne
    }

    public static func !=(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return !(lhs == rhs)
    }

    public var isValid: Bool {
        self != kCLLocationCoordinate2DInvalid
    }

}
