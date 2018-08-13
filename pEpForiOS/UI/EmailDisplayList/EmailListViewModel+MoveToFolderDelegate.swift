//
//  EmailListViewController+MoveToFolderDelegate.swift
//  pEp
//
//  Created by Borja González de Pablo on 04/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

extension EmailListViewModel: MoveToFolderDelegate {
    func didmove(messages: [Message]) {
        var ips = [IndexPath]()
        var pms = [MessageViewModel]()
        messages.forEach { (msg) in
            let ind = index(of: msg)!
            let pm = self.messages.object(at: ind)!
            pms.append(pm)
            let ip = IndexPath(row: ind, section: 0)
            ips.append(ip)
        }
        deletePreviewMessagesHelper(previewMEssages: pms)
        emailListViewModelDelegate?.emailListViewModel(viewModel: self, didRemoveDataAt: ips)
    }

    func deletePreviewMessagesHelper(previewMEssages: [MessageViewModel]) {
        previewMEssages.forEach { (pm) in
            self.messages.remove(object: pm)
        }
    }

    func didMove() {
        reloadData()
    }

}
