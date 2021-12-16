//
//  AnyPublisher+Helper.swift
//  InteractiveVideoPlayer
//
//  Created by Farshad Mousalou on 12/16/21.
//

import Foundation
import Combine

/**
 <# Property Summery Here#>
 */
struct AnyCombineObserver<Output, Failure: Error> {

    /// <#Description#>
    let onNext: ((Output) -> Void)

    /// <#Description#>
    let onError: ((Failure) -> Void)

    /// <#Description#>
    let onCompleted: (() -> Void)
}

/// <#Description#>
struct CombineDisposable {

    /// <#Description#>
    let dispose: () -> Void
}

extension AnyPublisher {

    /// Create `AnyPublisher` instance
    /// - seealso: `RxSwift.Observable.create(:)`
    /// - Parameter subscribe: the AnyObserver
    /// - Returns: return `AnyPublisher` instance
    static func create(subscribe: @escaping (AnyCombineObserver<Output, Failure>) -> CombineDisposable) -> Self {
        let subject = PassthroughSubject<Output, Failure>()
        var disposable: CombineDisposable?
        return subject
            .handleEvents(receiveSubscription: { _ in
                disposable = subscribe(AnyCombineObserver(
                    onNext: { output in subject.send(output) },
                    onError: { failure in subject.send(completion: .failure(failure)) },
                    onCompleted: { subject.send(completion: .finished) }
                ))
            }, receiveCancel: { disposable?.dispose() })
            .eraseToAnyPublisher()
    }
}

extension AnyPublisher {

    /// Convert `AnyPublisher` to `Future` to just emit on element on stream.
    ///
    /// - seealso: `RxSwift.Observable.asSingle()` document.
    /// - Returns: The `Future` that produce only one element on stream.
    func asFuture() -> Future<Output, Failure> {
        return Future { promise in
            var ticket: AnyCancellable?
            ticket = self.sink(receiveCompletion: {
                ticket?.cancel()
                ticket = nil
                switch $0 {
                case .failure(let error):
                    promise(.failure(error))
                case .finished:
                    log.debug("\($0)")
                }
            }, receiveValue: {
                ticket?.cancel()
                ticket = nil
                promise(.success($0))
            })
        }
    }

}
