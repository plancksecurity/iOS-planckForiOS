//
//  ErrorPropagator.swift
//  pEp
//
//  Created by Xavier Algarra on 10/11/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

/// Conform to this if you want to be a subscriber of ErrorPropagator.
public protocol ErrorPropagatorSubscriber: class {
    /// Called whenever an Error is added.
    /// - Parameters:
    ///   - propagator: the sender
    ///   - error: the error that has been added to the ErrorPropagator
    func error(propagator: ErrorPropagator, error: Error)
}

public protocol ErrorContainerProtocol {
    var error: Error? { get }
    /// Adds an error to the container. If an error has been reported before your call will be
    /// ignored.
    func addError(_ error: Error)
    /// Whether or not an error has been reported before. Calling after calling `reset()`
    /// previously reported error are ignored.
    var hasErrors: Bool { get }
    /// Forgets all previously reported errors
    func reset()
}

extension ErrorPropagator {

    /// Container that holds the first added error.
    class ErrorContainer: ErrorContainerProtocol {

        // MARK: - ErrorContainerProtocol

        public private(set) var error: Error?

        public func addError(_ error: Error) {
            if self.error == nil {
                self.error = error
            }
        }

        public var hasErrors: Bool {
            return error != nil
        }

        public func reset() {
            error = nil
        }
    }
}

/// An Error Container that holds errors and informs the subscriber in case an error is added to
/// the container.
public class ErrorPropagator: ErrorContainerProtocol {
    private var errorContainer: ErrorContainerProtocol
    /// Is informed whenever an Error is added.
    public weak var subscriber: ErrorPropagatorSubscriber?

    public init(subscriber: ErrorPropagatorSubscriber? = nil,
                errorContainer: ErrorContainerProtocol? = nil) {
        self.errorContainer = errorContainer ?? ErrorContainer()
        self.subscriber = subscriber
    }

    // MARK: - ErrorContainerProtocol

    public var error: Error? {
        return errorContainer.error
    }

    public func addError(_ error: Error) {
        errorContainer.addError(error)
        reportError()
    }

    public var hasErrors: Bool {
        errorContainer.hasErrors
    }

    public func reset() {
        errorContainer.reset()
    }
}

// MARK: - Private

extension ErrorPropagator {

    private func reportError() {
        guard let error = error else {
            Log.shared.errorAndCrash("Should not be called in success case")
            return
        }
        subscriber?.error(propagator: self, error: error)
    }
}
