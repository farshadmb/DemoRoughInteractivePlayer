//
//  VideoPlayerViewController.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/16/21.
//

import UIKit
import PureLayout
import RxCocoa
import RxSwift
import AVFoundation

class VideoPlayerViewController: NiblessViewController, BindableType {

    var viewModel: VideoPlayerViewModel?

    @NibWrapper
    private var controlView: VideoControlView

    @LateInit
    private var playerContentView: UIView

    @LateInit
    private var loadingIndicatorView: UIActivityIndicatorView

    @LateInit
    private var controlHeightConstraint: NSLayoutConstraint

    let disposeBag = DisposeBag()

    override init() {
        super.init()
    }

    deinit {
        viewModel = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configVideoPlayerView()
        configControlView()
        configLoadingIndiciatorView()
        rx.shakeMotion.bind(onNext: { _ in print("Shaked Detected!") }).disposed(by: disposeBag)
        view.backgroundColor = .black
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel?.loadVideo()
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate {[unowned self] (_) in

            let isLandsacpe = UIDevice.current.orientation.isLandscape
            updateControlView(height: isLandsacpe ? 0.15 : 0.25)
            view.layoutIfNeeded()

        } completion: { (_) in

        }

    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let frame = self.playerContentView.layer.bounds
        self.playerContentView.layer.sublayers?.forEach({ $0.frame = frame })
    }

    private func configControlView() {
        view.addSubview(controlView)
        controlView.backgroundColor = .init(white: 0.0, alpha: 0.5)
        controlView.autoPinEdgesToSuperviewSafeArea(with: UIEdgeInsets(top: 0, left: 16, bottom: 5, right: 16),
                                                    excludingEdge: .top)

        let isLandsacpe = !(self.interfaceOrientation == .portrait)
        updateControlView(height: isLandsacpe ? 0.15 : 0.25)
        controlView.layer.cornerRadius = 9
        controlView.clipsToBounds = true
    }

    private func updateControlView(height: CGFloat) {

        if $controlHeightConstraint != nil {
            $controlHeightConstraint?.autoRemove()
        }

        controlHeightConstraint = controlView.autoMatch(.height, to: .width, of: view, withMultiplier: height)
    }

    private func configVideoPlayerView() {
        playerContentView = UIView()

        view.addSubview(playerContentView)
        playerContentView.backgroundColor = .black
        playerContentView.autoPinEdge(toSuperviewSafeArea: .leading)
        playerContentView.autoPinEdge(toSuperviewSafeArea: .trailing)

        playerContentView.autoPinEdge(toSuperviewSafeArea: .top, withInset: 0, relation: .greaterThanOrEqual)

        playerContentView.autoCenterInSuperview()

    }

    private func configLoadingIndiciatorView() {
        loadingIndicatorView = UIActivityIndicatorView(style: .large)
        loadingIndicatorView.hidesWhenStopped = true
        loadingIndicatorView.color = .white

        loadingIndicatorView.stopAnimating()
        view.addSubview(loadingIndicatorView)
        loadingIndicatorView.autoCenterInSuperview()

    }

    func bindViewModel() {
        guard let viewModel = viewModel else {
            return
        }

        controlView.bind(to: viewModel)
        rx.shakeMotion.bind(to: viewModel.shakeEvent).disposed(by: disposeBag)

        viewModel.bind(viewLayer: playerContentView.layer)
        viewModel.isLoading.asDriver(onErrorDriveWith: .never())
            .asObservable().bind(to: loadingIndicatorView.rx.isAnimating).disposed(by: disposeBag)
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
    }

}

extension Reactive where Base: VideoPlayerViewController {

    var shakeMotion: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(Base.motionEnded(_:with:)))
            .do(onNext: { (values) in
                print(values)
            })
            .compactMap { $0[safe:1] as? UIEvent }
            .filter { $0.subtype == .motionShake }
            .map { _ in return Void() }
            .take(until: deallocating)

        return ControlEvent(events: source)
    }

}

protocol VideoPlayerViewControllerFactory {

    func makeVideoPlayerViewController() -> VideoPlayerViewController
}
