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

    private var currentLocation: Observable<CLLocationCoordinate2D> {
        return locationManager.rx.location.compactMap({ $0?.coordinate })
    }

    let disposeBag = DisposeBag()

    init() {
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.activityType = .other

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
            .flatMapLatest {[weak self] (status) -> Observable<CLLocationCoordinate2D> in
                guard let `self` = self, status == .authorizedWhenInUse else {
                    return .just(kCLLocationCoordinate2DInvalid)
                }

                self.locationManager.startUpdatingLocation()
                return self.currentLocation
            }
            .distinctUntilChanged({ (location1, location2) -> Bool in
                return location1.latitude == location2.latitude && location1.longitude == location2.longitude
            })
            .share()
            .share()

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
