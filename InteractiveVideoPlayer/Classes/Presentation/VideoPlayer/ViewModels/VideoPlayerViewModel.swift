//
//  VideoPlayerViewModel.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/16/21.
//

import Foundation
import RxSwift
import RxCocoa

// http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4

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
    private let currentProgressSubject = BehaviorSubject<Float>(value: 0)
    private let playerStateSubject = ReplaySubject<PlayerState>.create(bufferSize: 1)

    let isLoading = BehaviorSubject(value: false)

    let locationProvider: Any
    let gyroscopeProvider: Any
    let playerProvider: VideoPlayerProvider

    let disposeBag = DisposeBag()

    init(locationProvider: Any, gyroscopeProvider: Any, playerProvider: VideoPlayerProvider ) {
        self.locationProvider = locationProvider
        self.gyroscopeProvider = gyroscopeProvider
        self.playerProvider = playerProvider
        commonInit()
        observerSensors()

    }

    func bind(viewLayer: CALayer) {

    }

    func loadVideo(url: URL) {
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
        timeLineSlider = currentProgressSubject.asObserver()
    }

    private func observerSensors() {

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
