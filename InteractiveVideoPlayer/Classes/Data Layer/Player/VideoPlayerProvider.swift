//
//  VideoPlayer.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/16/21.
//

import Foundation
import QuartzCore
import RxCocoa
import RxSwift

protocol VideoPlayerProvider {

    var currenTime: Observable<TimeInterval> { get }

    var duration: Observable<TimeInterval> { get }

    var playerStatus: Observable<VideoPlayerStatus> { get }

    func loadMedia(url: URL) -> Single<Bool>

    @discardableResult
    func playVideo() -> Single<Bool>

    @discardableResult
    func pauseVideo() -> Single<Bool>

    @discardableResult
    func stopVideo() -> Single<Bool>

    @discardableResult
    func resetVideo() -> Single<Bool>

    func seekVideo(toTime time: TimeInterval) -> Single<Bool>

    func seekVideo(toPercent: Float) -> Single<Bool>

    func videoPreview() -> CALayer

    func set(volume: Float) -> Single<Bool>

}

enum VideoPlayerStatus {
    case notReady
    case loading
    case ready
    case playing
    case pause
    case buffering
    case stop
}
