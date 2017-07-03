//
//  EmailListViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 23/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class EmailListViewModel : FilterUpdateProtocol{


    var folderToShow: Folder?
    let cellsInUse = NSCache<NSString, EmailListViewCell>()
    var delegate : tableViewUpdate?

    var filterEnabled = false

    init(config: EmailListConfig?, delegate: tableViewUpdate) {
        //MessageModelConfig.messageFolderDelegate = self
        folderToShow = config?.folder
        self.delegate = delegate
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

    // MARK: - Content Search

    func filterContentForSearchText(searchText: String? = nil, clear: Bool) {
        if clear {
            if filterEnabled {
                folderToShow?.filter = Filter.removeSearchFilter(filter: folderToShow?.filter as! Filter)
            } else {
                updateFilter(filter: Filter.unified())
            }
        } else {
            if let text = searchText, text != "" {
                let f = Filter.search(subject: text)
                if filterEnabled {
                    f.and(filter: Filter.unread())
                    updateFilter(filter: f)
                } else {
                    updateFilter(filter: f)
                }
            }
        }
    }

    public func updateFilter(filter: Filter) {
        folderToShow?.updateFilter(filter: filter)
        self.delegate?.updateView()
    }


}


extension EmailListViewModel: MessageFolderDelegate {
    public func didChange(messageFolder: MessageFolder) {
        //GCD.onMainWait {
        //    self.didChangeInternal(messageFolder: messageFolder)
        //}
    }
}
