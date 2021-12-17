//
//  AVVideoPlayerProvider.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/16/21.
//

import Foundation
import RxSwift
import RxCocoa
import RxAVFoundation
import AVFoundation

private let kAssetTracksKey = "tracks"
private let kAssetPlayableKey = "playable"
private let kAssetDuration = "duration"

// that means AVPlayerItem need to load buffer and current buffer is empty
private let kCurrentItemPlaybackBufferEmptyKey = "currentItem.playbackBufferEmpty"

private let kCurrentItemPlaybackBufferFullKey = "currentItem.playbackBufferFull"

// that means AVPlayerItem need
private let kCurrentItemPlaybackLikelyToKeepUp = "currentItem.playbackLikelyToKeepUp"

// that means AVPlayerItem load 5 second from begin time
private let kCurrentItemPlaybackLoadedTimeRange = "currentItem.loadedTimeRanges"

final class AVVideoPlayerProvider: VideoPlayerProvider {

    var currenTime: Observable<TimeInterval> {
        currentTimeSubject.asObservable()
    }

    var duration: Observable<TimeInterval> {
        durationSubject.asObservable()
    }

    var playerStatus: Observable<VideoPlayerStatus> {
        return Observable.merge(player.rx.status.map(mapPlayer(status:)),
                                playerStateSubject.asObservable())
    }

    let player = AVPlayer()

    private let currentTimeSubject = ReplaySubject<TimeInterval>.create(bufferSize: 1)
    private let durationSubject = ReplaySubject<TimeInterval>.create(bufferSize: 1)
    private let playerStateSubject = BehaviorRelay<VideoPlayerStatus>(value: .notReady)

    private let disposeBag = DisposeBag()

    init() {
        configPlayer()
        observePlayer()
    }

    func loadMedia(url: URL) -> Single<Bool> {
        let keys = [kAssetPlayableKey, kAssetDuration]
        let item = AVPlayerItem(asset: AVAsset(url: url), automaticallyLoadedAssetKeys: keys)
        player.replaceCurrentItem(with: item)
        player.rate = 0.0

        playerStateSubject.accept(.loading)

        let source = item.asset.rx.loadValuesForKeys(keys)
            .flatMap {[unowned item] _ -> Observable<Bool> in
                if !item.asset.isPlayable {
                    item.asset.cancelLoading()
                }
                item.asset.cancelLoading()
                return Observable.just(item.asset.isPlayable)
            }
            .share(replay: 1, scope: .whileConnected)

        source.filter({ $0 })
            .withLatestFrom(item.rx.duration)
            .map({ CMTimeGetSeconds($0) })
            .bind(to: durationSubject)
            .disposed(by: disposeBag)

        source.subscribe(with: self) { (object, result) in
            object.playerStateSubject.accept(result ? .ready : .notReady)
        } onError: { (object, _) in
            object.playerStateSubject.accept(.notReady)
        }
        .disposed(by: disposeBag)

        return source.asSingle()

    }

    func playVideo() -> Single<Bool> {

        guard player.currentItem != nil else {
            return .just(false)
        }

        player.play()
        player.rate = 1.0
        player.volume = 1.0

        playerStateSubject.accept(.playing)

        return .just(true)
    }

    func pauseVideo() -> Single<Bool> {
        player.rate = 0
        player.pause()
        playerStateSubject.accept(.pause)
        return .just(true)
    }

    func stopVideo() -> Single<Bool> {

        player.seek(to: .zero) { (_) in

        }

        player.pause()
        player.rate = 0.0
        playerStateSubject.accept(.stop)

        return .just(true)
    }

    func resetVideo() -> Single<Bool> {
        seekVideo(toTime: 0)
    }

    func seekVideo(toTime time: TimeInterval) -> Single<Bool> {
        return Observable<Bool>.create {[weak player] (observer) -> Disposable in

            guard let player = player else {
                return Disposables.create()
            }

            let time = CMTime(seconds: time, preferredTimescale: .init(1 * NSEC_PER_SEC))

            player.seek(to: time) { (result) in
                observer.onNext(result)
                observer.onCompleted()
            }

            return Disposables.create()
        }
        .asSingle()
    }

    func seekVideo(toPercent percent: Float) -> Single<Bool> {
        return durationSubject.asObservable()
            .first().compactMap { $0 }.asObservable().asSingle()
            .flatMap { [weak self] (duration) -> Single<Bool> in
                   guard let strongSelf = self else {
                       return .just(false)
                   }

                   return strongSelf.seekVideo(toTime: duration * Double(percent))
            }

    }

    func videoPreview() -> CALayer {
        let previewLayer = AVPlayerLayer(player: player)
        previewLayer.videoGravity = .resizeAspect

        return previewLayer
    }

    func set(volume: Float) -> Single<Bool> {
        player.volume = volume
        return .just(true)
    }

    private func configPlayer() {

        player.preventsDisplaySleepDuringVideoPlayback = true
        player.actionAtItemEnd  = .pause
        player.automaticallyWaitsToMinimizeStalling = true

    }

    private func observePlayer() {

        player.rx.observe(CMTime.self, "currentItem.currentTime")
            .compactMap({ $0 })
            .map { CMTimeGetSeconds($0) }
            .bind(to: currentTimeSubject)
            .disposed(by: disposeBag)

        let timeScale = CMTime(seconds: 1, preferredTimescale: .init(1 * NSEC_PER_SEC))

        player.rx.periodicTimeObserver(interval: timeScale)
            .withUnretained(player)
            .compactMap({ $0.0.currentItem?.currentTime() })
            .map { CMTimeGetSeconds($0) }
            .bind(to: currentTimeSubject)
            .disposed(by: disposeBag)

        player.rx.observe(Bool.self, kCurrentItemPlaybackBufferEmptyKey)
            .compactMap({ $0 })
            .subscribe(with: self, onNext: { (object, result) in
                guard result else {
                    return
                }

                object.playerStateSubject.accept(.buffering)
            })
            .disposed(by: disposeBag)

        player.rx.observe(Bool.self, kCurrentItemPlaybackLikelyToKeepUp)
            .compactMap({ $0 })
            .subscribe(with: self, onNext: { (object, result) in
                guard result else {
                    return
                }

                if object.player.rate < 0.1 && object.playerStateSubject.value == .buffering {
                    object.playVideo().subscribe().disposed(by: object.disposeBag)
                }

            })
            .disposed(by: disposeBag)

        AVAudioSession.sharedInstance().rx.observe(Float.self, "outputVolume")
            .asObservable()
            .compactMap({ $0 })
            .flatMap(set(volume:))
            .subscribe()
            .disposed(by: disposeBag)
            
    }

    private func mapPlayer(status: AVPlayer.Status) -> VideoPlayerStatus {
        switch status {
        case .readyToPlay:
            return .ready
        default:
            return .notReady
        }
    }

}
