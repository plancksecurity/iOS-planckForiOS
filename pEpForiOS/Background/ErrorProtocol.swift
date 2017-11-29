//
//  ServiceErrorProtocol.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 For exchanging errors between `BaseOperation`s.
 */
public protocol ServiceErrorProtocol {
    var error: Error? { get }
    func addError(_ error: Error)
    func hasErrors() -> Bool
}

open class ErrorContainer: ServiceErrorProtocol { //BUFF:
    public var error: Error?

    public init() {}

    public func addError(_ error: Error) {
        if self.error == nil {
            self.error = error
        }
    }

    public func hasErrors() -> Bool {
        return error != nil
    }
}

//open class ReportingErrorContainer {
//    private var errors = [Error]()
//
//    public init() {}
//
//    public func addError(_ error: Error) {
//        errors.append(error)
//    }
//
//    public func hasErrors() -> Bool {
//        return errors.count > 0
//    }
//
//    public func getErrors() -> [Error] {
//        return errors
//    }
//}

//BUFF: move

public protocol ReportingErrorContainerDelegate: class {
    func reportingErrorContainer(_ errorContainer: ReportingErrorContainer, didReceive error: Error)
}

open class ReportingErrorContainer: ErrorContainer {
    weak public var delegate: ReportingErrorContainerDelegate?

    public init(delegate: ReportingErrorContainerDelegate) {
        self.delegate = delegate
        super.init()
    }

    override public func addError(_ error: Error) {
        super.addError(error)
        delegate?.reportingErrorContainer(self, didReceive: error)
    }
}

