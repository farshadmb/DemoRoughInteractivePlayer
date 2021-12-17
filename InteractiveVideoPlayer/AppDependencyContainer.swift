//
//  AppDependencyContainer.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/17/21.
//

import Foundation
import RxSwift
import Resolver

final class AppDependencyContainer {

    let resolver: Resolver

    init(resolver: Resolver = .main) {
        self.resolver = resolver
        registerDependencies()
    }

    func registerDependencies() {
        #if targetEnvironment(simulator) && os(iOS)
        resolver.register {
            FakeGPSLocationProvider(timeInterval: 1)
        }
        .implements(LocationProvider.self)
        .scope(.application)
        #else
        resolver.register {
            GPSLocationProvider()

        }
        .implements(LocationProvider.self).scope(.application)
        #endif

        #if targetEnvironment(simulator) && os(iOS)
        resolver.register {
            FakeGyroscopMotionProvider(timeInterval: 1)
        }
        .implements(GyroscopMotionProvider.self).scope(.application)
        #else
        resolver.register {
            CoreMotionProvider()
        }
        .implements(GyroscopMotionProvider.self, name: "MotionProvider").scope(.application)
        #endif

        resolver.register {
            AVVideoPlayerProvider() as VideoPlayerProvider
        }
        .implements(VideoPlayerProvider.self)
        .scope(.unique)
    }
}

extension AppDependencyContainer: VideoPlayerViewModelFactory {

    func makeVideoPlayerViewModel() -> VideoPlayerViewModel {
        return VideoPlayerViewModel()
    }
}

/*
extension AppDependencyContainer: CoordinatorFactory {

    func makeAppCoordinator() -> AppCoordinator {
        let coordinator = AppCoordinator(factory: self)
        return coordinator
    }

}
*/

extension AppDependencyContainer: VideoPlayerViewControllerFactory {

    func makeVideoPlayerViewController() -> VideoPlayerViewController {
        let vc = VideoPlayerViewController()
        vc.bind(to: makeVideoPlayerViewModel())
        return vc
    }
}