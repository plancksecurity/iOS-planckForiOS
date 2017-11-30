//
//  ReportingErrorContainer.swift
//  pEp
//
//  Created by Andreas Buff on 30.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Conform tho this if you want to get informed about errors reported to ReportingErrorContainer.
public protocol ReportingErrorContainerDelegate: class {
    func reportingErrorContainer(_ errorContainer: ReportingErrorContainer, didReceive error: Error)
}

/// Same as ErrorContainer, but offers delegate that is informed in case of any reported error.
public class ReportingErrorContainer: ErrorContainer {
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
