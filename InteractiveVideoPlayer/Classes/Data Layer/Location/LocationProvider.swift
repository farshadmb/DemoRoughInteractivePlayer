//
//  LocationProvider.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/17/21.
//

import Foundation
import RxSwift
import CoreLocation

protocol LocationProvider: AnyObject {

    func startObservation() -> Observable<Result<Bool, Error>>

    func getCurrentLocation() -> Observable<CLLocationCoordinate2D>

    func cancel() -> Observable<Bool>
}
