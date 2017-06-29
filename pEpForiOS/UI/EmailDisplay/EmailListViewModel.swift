//
//  EmailListViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 23/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class EmailListViewModel {


    var folderToShow: Folder?
    let cellsInUse = NSCache<NSString, EmailListViewCell>()

    var filterEnabled = false

    init(config: EmailListConfig?) {
        //MessageModelConfig.messageFolderDelegate = self
        folderToShow = config?.folder
    }

    var count : Int {
        if let folder = folderToShow {
            return folder.messageCount()
        }
        return 0
    }

    subscript(index: Int) -> Message? {
        get {
            if let folder = folderToShow, folder.messageCount() >= index {
                return self.folderToShow?.messageAt(index: index)
            }
            return nil
        }
    }

    // MARK: - Message -> Cell association

    func associate(cell: EmailListViewCell, position: Int) {
        if let message = self[position] {
            cellsInUse.setObject(cell, forKey: keyFor(message: message))
        }
    }

    func cellFor(message: Message) -> EmailListViewCell? {
        return cellsInUse.object(forKey: keyFor(message: message))
    }

    func keyFor(message: Message) -> NSString {
        let parentName = message.parent?.name ?? "unknown"
        return "\(message.uuid) \(parentName) \(message.uuid)" as NSString
    }

}


extension EmailListViewModel: MessageFolderDelegate {
    public func didChange(messageFolder: MessageFolder) {
        //GCD.onMainWait {
        //    self.didChangeInternal(messageFolder: messageFolder)
        //}
    }
}
