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
    var delegate : TableViewUpdate?

    var filterEnabled = false

    var enabledFilters : Filter?

    var lastFilterEnabled: Filter?

    init(config: EmailListConfig?, delegate: TableViewUpdate) {
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
        let parentName = message.parent.name 
        return "\(message.uuid) \(parentName) \(message.uuid)" as NSString
    }

    // MARK: - Content Search

    func filterContentForSearchText(searchText: String? = nil, clear: Bool) {
        if clear {
            if filterEnabled {
                if let f = folderToShow?.filter {
                    folderToShow?.filter = Filter.removeSearchFilter(filter: f)
                }
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

    public func enableFilter() {
        if let lastFilter = lastFilterEnabled {
            updateFilter(filter: lastFilter)
        } else {
            updateFilter(filter: Filter.unread())
        }
    }

    public func updateFilter(filter: Filter) {
        if let temporalfilters = folderToShow?.filter {
            temporalfilters.and(filter: filter)
            enabledFilters = folderToShow?.updateFilter(filter: temporalfilters)
        } else {
            enabledFilters = folderToShow?.updateFilter(filter: filter)
        }

        self.delegate?.updateView()
    }

    public func resetFilters() {
        if let f = folderToShow {
            lastFilterEnabled = f.filter
            if f.isUnified {
                let _ = folderToShow?.updateFilter(filter: Filter.unified())
            } else {
                let _ = folderToShow?.updateFilter(filter: Filter.empty())
            }
        }
        self.delegate?.updateView()
    }


}


extension EmailListViewModel: MessageFolderDelegate {
    public func didChange(messageFolder: MessageFolder) {

    }
}
