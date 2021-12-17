//
//  VideoPlayerViewModel.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/16/21.
//

import Foundation
import RxSwift
import RxCocoa
import Resolver

// swiftlint:disable:next force_unwrapping
let testURL = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4")!

final class VideoPlayerViewModel {

    @LateInit
    private(set) var playTap: AnyObserver<Void>

    @LateInit
    private(set) var stopTap: AnyObserver<Void>

    @LateInit
    private(set) var forwardTap: AnyObserver<Void>

    @LateInit
    private(set) var backwardTap: AnyObserver<Void>

    @LateInit
    private(set) var resetTap: AnyObserver<Void>

    @LateInit
    private(set) var timeLineSlider: AnyObserver<Float>

    @LateInit
    private(set) var shakeEvent: AnyObserver<Void>

    var currentProgress: Driver<Float> {
        currentProgressSubject.asDriver(onErrorDriveWith: .never())
    }

    var isPlaying: Driver<Bool> {
        return playerState.map { $0 == .playing }
    }

    var isStop: Driver<Bool> {
        return playerState.map { $0 == .stopped }
    }

    var isReady: Driver<Bool> {
        return playerState.map { $0 == .ready }
    }

    var playerState: Driver<PlayerState> {
        return playerStateSubject.asDriver(onErrorDriveWith: .never())
    }

    private let playTapSubject = PublishSubject<Void>()
    private let stopTapSubject = PublishSubject<Void>()
    private let forwardTapSubject = PublishSubject<Void>()
    private let backwardTapSubject = PublishSubject<Void>()
    private let resetTapSubject = PublishSubject<Void>()
    private let sliderSubject = PublishSubject<Float>()
    private let currentProgressSubject = BehaviorSubject<Float>(value: 0)
    private let playerStateSubject = ReplaySubject<PlayerState>.create(bufferSize: 1)
    private let shakeSubject = PublishSubject<Void>()

    let isLoading = BehaviorSubject(value: false)

    @LazyInjected
    private(set) var locationProvider: LocationProvider

    @LazyInjected
    private(set) var gyroscopeProvider: GyroscopMotionProvider

    @Injected
    private(set) var playerProvider: VideoPlayerProvider

    let disposeBag = DisposeBag()

    init() {

        commonInit()
        observerSensors()
        observePlayer()
        observeInputs()
            
    }

    deinit {
        locationProvider.cancel()
            .subscribe().dispose()
        gyroscopeProvider.stop().subscribe().dispose()
    }

    func bind(viewLayer: CALayer) {
        let previewLayer = playerProvider.videoPreview()
        previewLayer.frame = viewLayer.bounds
        viewLayer.addSublayer(previewLayer)

    }

    func loadVideo(url: URL = testURL) {
        playerProvider.loadMedia(url: url)
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func commonInit() {
        playTap = playTapSubject.asObserver()
        stopTap = stopTapSubject.asObserver()
        resetTap = resetTapSubject.asObserver()
        backwardTap = backwardTapSubject.asObserver()
        forwardTap = forwardTapSubject.asObserver()
        timeLineSlider = sliderSubject.asObserver()
        shakeEvent = shakeSubject.asObserver()
    }

    private func observerSensors() {
        locationProvider.startObservation()
            .subscribe().disposed(by: disposeBag)

        let locationSource = locationProvider.getCurrentLocation()

        locationSource
            .bind { (location) in
                log.debug("Location is \(location)")
            }
            .disposed(by: disposeBag)

        locationSource.asObservable()
            .map { _ in Void() }
            .bind(to: resetTapSubject)
            .disposed(by: disposeBag)

        gyroscopeProvider.start().subscribe().disposed(by: disposeBag)

        let gyroscopeSource = gyroscopeProvider.getRotatingData()
            .share(replay: 1, scope: .whileConnected)

        gyroscopeSource.bind { data in
            log.debug("Gyroscope is \(data)")
        }.disposed(by: disposeBag)

        gyroscopeSource
            .bind(with: self, onNext: { (object, data) in
                object.process(data: data)
            }).disposed(by: disposeBag)

    }

    private func observePlayer() {
        playerProvider.playerStatus.bind { (status) in
            log.debug("\(status)")
        }.disposed(by: disposeBag)

        playerProvider.playerStatus.asObservable()
            .map(map(status:))
            .bind(to: playerStateSubject).disposed(by: disposeBag)

        playerProvider.currenTime.bind {
            log.debug("\($0)")
        }.disposed(by: disposeBag)

        Observable.combineLatest(playerProvider.currenTime,playerProvider.duration, resultSelector: { currentTime, duration -> Float in
            guard duration > 0 else {
                return 0
            }

            return Float(currentTime / duration)
        })
        .bind(to: currentProgressSubject).disposed(by: disposeBag)

        playerProvider.playerStatus.asObservable().map { $0 == .buffering || $0 == .loading }
            .bind(to: isLoading).disposed(by: disposeBag)

    }

    func observeInputs() {

        resetTapSubject.asObservable().flatMap({ [unowned self] _ in playerProvider.resetVideo() }).subscribe().disposed(by: disposeBag)
        stopTapSubject.asObservable().flatMap({ [unowned self] _ in playerProvider.stopVideo() }).subscribe().disposed(by: disposeBag)
        playTapSubject.asObservable()
            .withLatestFrom(isPlaying)
            .flatMap({ [unowned self] isPlaying in isPlaying ? playerProvider.pauseVideo() : playerProvider.playVideo() })
            .subscribe().disposed(by: disposeBag)

        forwardTapSubject.asDriver(onErrorDriveWith: .never())
            .debounce(.milliseconds(500)).asObservable()
            .withLatestFrom(playerProvider.currenTime)
            .flatMap({ [unowned self] time in playerProvider.seekVideo(toTime: time + 15) }).subscribe().disposed(by: disposeBag)

        backwardTapSubject.asDriver(onErrorDriveWith: .never())
            .debounce(.milliseconds(500)).asObservable()
            .withLatestFrom(playerProvider.currenTime)
            .flatMap({ [unowned self] time in playerProvider.seekVideo(toTime: time - 15) })
            .subscribe().disposed(by: disposeBag)

        sliderSubject.asDriver(onErrorJustReturn: 0)
            .debounce(.milliseconds(500)).asObservable()
            .flatMap({ [unowned self] percent in playerProvider.seekVideo(toPercent: percent) })
            .subscribe().disposed(by: disposeBag)

        shakeSubject.asObservable().flatMap({ [unowned self] _ in playerProvider.pauseVideo() }).subscribe().disposed(by: disposeBag)
    }

    private func map(status: VideoPlayerStatus) -> PlayerState {
        switch status {
        case .buffering,.loading:
            return .loading
        case .notReady, .stop:
            return .stopped
        case .ready:
            return .ready
        case .playing:
            return .playing
        case .pause:
            return .paused
        }
    }

    private func process(data: GyroscopeData) {

        func rad2deg(_ number: Double) -> Double {
            return number * 180 / .pi
        }

        let deltaRanges = 0.9...1.5

        let zAngle = rad2deg(data.zRotating)
        let xAngle = rad2deg(data.xRotating)
        print(#function, zAngle, xAngle)

        guard deltaRanges ~= abs(data.xRotating), deltaRanges ~= abs(data.zRotating)  else {
            return
        }

        if data.xRotating.sign == .plus {
            playerProvider.set(volume: 0.75).subscribe().disposed(by: disposeBag)
        }else if data.xRotating.sign == .minus {
            playerProvider.set(volume: 0.25).subscribe().disposed(by: disposeBag)
        }

        if data.zRotating.sign == .plus {
            playerProvider.seekVideo(toPercent: 0.75).subscribe().disposed(by: disposeBag)
        }else if data.zRotating.sign == .minus {
            playerProvider.seekVideo(toPercent: 0.25).subscribe().disposed(by: disposeBag)
        }
    }
}

extension VideoPlayerViewModel {

    enum PlayerState: Int {
        case ready
        case stopped
        case playing
        case paused
        case loading
    }

}

protocol VideoPlayerViewModelFactory {

    func makeVideoPlayerViewModel() -> VideoPlayerViewModel
}
