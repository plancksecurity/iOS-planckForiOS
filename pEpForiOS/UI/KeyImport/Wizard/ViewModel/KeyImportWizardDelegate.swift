//
//  KeyImportWizardDelegate.swift
//  pEp
//
//  Created by Hussein on 06/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

public protocol KeyImportWizardDelegate: class {

    func showError(error: Error)
    func notifyUpdate()
}

