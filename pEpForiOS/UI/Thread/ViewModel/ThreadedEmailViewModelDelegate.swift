//
//  EmailViewModelDelegate.swift
//  pEp
//
//  Created by Borja González de Pablo on 18/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox

protocol ThreadedEmailViewModelDelegate: class, TableViewUpdate {
    func emailViewModel(viewModel: ThreadedEmailViewModel, didInsertDataAt index: Int)
    func emailViewModel(viewModel: ThreadedEmailViewModel, didUpdateDataAt index: Int)
    func emailViewModel(viewModel: ThreadedEmailViewModel, didRemoveDataAt index: Int)
    func emailViewModeldidChangeFlag(viewModel: ThreadedEmailViewModel)
}
