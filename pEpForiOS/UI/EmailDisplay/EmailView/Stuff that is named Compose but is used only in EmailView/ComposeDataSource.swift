//
//  TableDataModel.swift
//  MailComposer
//
//  Created by Igor Vojinovic on 11/4/16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import Foundation
import UIKit
import pEpIOSToolbox
import MessageModel

class ComposeDataSource: NSObject {
    var originalRows = [ComposeFieldModel]()
    var filteredRows = [ComposeFieldModel]()
    
    init(with dataArray: [[String: Any]]) {
        for item in dataArray {
            let row = ComposeFieldModel(with: item)
            originalRows.append(row)
        }
    }

    /**
     Caller decides which rows are actually visible.
     */
    public func filterRows(filter: (ComposeFieldModel) -> Bool) {
        filteredRows = originalRows.filter { filter($0) }
    }

    /// Decide on the rows that should be visible, based on the message.
    public func filterRows(message: Message?) {
        if let viewableAttachments = message?.viewableAttachments(),
            viewableAttachments.count == 0 {
            filterRows(filter: { $0.type != .mailingList && $0.type != .attachment} )
        } else {
            filterRows(filter: { $0.type != .mailingList} )
        }
        Log.shared.info("filtering rows")
    }

    func numberOfRows() -> Int {
        let visibleRows = getVisibleRows()
        return visibleRows.count
    }

    func getVisibleRows() -> [ComposeFieldModel] {
        return filteredRows
    }

    func getRow(at index: Int) -> ComposeFieldModel {
        let visibleRows = getVisibleRows()
        return visibleRows[index]
    }
}
