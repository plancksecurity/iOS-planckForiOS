//
//  EmailDetailViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 04.12.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol EmailDetailViewModelDelegate: EmailDisplayViewModelDelegate {
    //BUFF: All moved to EmailDisplayViewModelDelegate. Will be filled with list specific stuff soon. Stay tuned.
}

// 
class EmailDetailViewModel: EmailDisplayViewModel {

    // MARK: - Life Cycle

//        init(emailListViewModelDelegate: EmailDisplayViewModelDelegate? = nil,
//             folderToShow: DisplayableFolderProtocol) {
//            self.emailListViewModelDelegate = emailListViewModelDelegate
//            self.folderToShow = folderToShow
//
//            // We intentionally do *not* start monitoring. Respiosibility is on currently on VC.
//            messageQueryResults = MessageQueryResults(withFolder: folderToShow,
//                                                           filter: nil,
//                                                           search: nil)
//            messageQueryResults.rowDelegate = self
//            // Threading feature is currently non-existing. Keep this code, might help later.
//    //        self.oldThreadSetting = AppSettings.shared.threadedViewEnabled
//        }

}
