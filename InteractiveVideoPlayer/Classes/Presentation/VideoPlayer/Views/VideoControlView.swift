//
//  VideoControlView.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/16/21.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift

class VideoControlView: UIView, BindableType {

    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var stop: UIButton!
    @IBOutlet weak var resetButton: UIButton!

    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var backwardButton: UIButton!
    @IBOutlet weak var timelineSlider: UISlider!

    var viewModel: VideoPlayerViewModel?

    let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        // configuration
        configureButtons()
    }

    func bindViewModel() {
        guard let viewModel = viewModel else {
            return
        }

        playPauseButton.rx.tap.bind(to: viewModel.playTap).disposed(by: disposeBag)
        resetButton.rx.tap.bind(to: viewModel.resetTap).disposed(by: disposeBag)
        stop.rx.tap.bind(to: viewModel.stopTap).disposed(by: disposeBag)

        forwardButton.rx.tap.bind(to: viewModel.forwardTap).disposed(by: disposeBag)
        backwardButton.rx.tap.bind(to: viewModel.backwardTap).disposed(by: disposeBag)

        timelineSlider.rx.value.bind(to: viewModel.timeLineSlider).disposed(by: disposeBag)

        viewModel.isLoading.map({ !$0 }).bind(to: rx.isUserInteractionEnabled).disposed(by: disposeBag)

        viewModel.isPlaying.asObservable().bind {[weak self] (bool) in
            self?.updatePlayPauseButton(for: bool)
        }
        .disposed(by: disposeBag)

        viewModel.isStop.filter({ $0 })
            .asObservable().bind {[weak self] (bool) in
            self?.updatePlayPauseButton(for: !bool)
            }
        .disposed(by: disposeBag)

        viewModel.currentProgress.asObservable().bind(to: timelineSlider.rx.value).disposed(by: disposeBag)

    }

    private func configureButtons() {
        subviews.compactMap({ $0 as? UIButton })
            .forEach({ $0.tintColor = .white })

        updatePlayPauseButton(for: false)

        stop.setImage(UIImage.Symbols.stop.templateImage, for: .normal)
        stop.setImage(UIImage.Symbols.stop.templateImage, for: .highlighted)
        stop.setImage(UIImage.Symbols.stop.templateImage, for: .focused)

        resetButton.setImage(UIImage.Symbols.reset.templateImage, for: .normal)
        resetButton.setImage(UIImage.Symbols.reset.templateImage, for: .highlighted)
        resetButton.setImage(UIImage.Symbols.reset.templateImage, for: .focused)

        forwardButton.setImage(UIImage.Symbols.forward.templateImage, for: .normal)
        forwardButton.setImage(UIImage.Symbols.forward.templateImage, for: .highlighted)
        forwardButton.setImage(UIImage.Symbols.forward.templateImage, for: .focused)

        backwardButton.setImage(UIImage.Symbols.backward.templateImage, for: .normal)
        backwardButton.setImage(UIImage.Symbols.backward.templateImage, for: .highlighted)
        backwardButton.setImage(UIImage.Symbols.backward.templateImage, for: .focused)

    }

    private func updatePlayPauseButton(for isPlaying: Bool) {

        let image: ImageAssets = isPlaying ? UIImage.Symbols.pause : .play

        playPauseButton.setImage(image.templateImage, for: .normal)
        playPauseButton.setImage(image.templateImage, for: .highlighted)
        playPauseButton.setImage(image.templateImage, for: .focused)

    }

}
