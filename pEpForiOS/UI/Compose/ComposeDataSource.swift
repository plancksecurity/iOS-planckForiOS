//
//  TableDataModel.swift
//  MailComposer
//
//  Created by Igor Vojinovic on 11/4/16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import Foundation
import UIKit

import MessageModel

class ComposeDataSource: NSObject {
    var originalRows = [ComposeFieldModel]()
    var filteredRows = [ComposeFieldModel]()
    var ccEnabled = false
    
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
        filteredRows = originalRows.filter() { return filter($0) }
    }

    /**
     Decide on the rows that should be visible, based on the message.
     */
    public func filterRows(message: Message?) {
        filterRows(filter: { return $0.type != .mailingList})
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

    // MARK: - AttachmentDataSource

    struct AttachmentDataSource {
        struct Row {
            let fileName: String?
            let fileExtesion: String?
        }
        private var nonInlinedAttachments = [Attachment]()
        let mimeTypeUtil = MimeTypeUtil()

        func attachments() -> [Attachment] {
            return nonInlinedAttachments
        }

        func count() -> Int {
            return nonInlinedAttachments.count
        }

        subscript(index: Int) -> Row? {
            if index < 0 || index > (nonInlinedAttachments.count - 1) {
                Log.shared.errorAndCrash(component: #function, errorString: "Index out of bounds")
                return nil
            }
            let attachment = nonInlinedAttachments[index]
            return Row(fileName: attachment.fileName,
                       fileExtesion: mimeTypeUtil?.fileExtension(mimeType: attachment.mimeType) ?? "")
        }

        /// Adds an attachment to the data source and returns the index it has been inserted in.
        ///
        /// - Parameter attachment: attachment to add
        /// - Returns: index the attachment has been inserted in
        @discardableResult mutating func add(attachment: Attachment) -> Int {
            nonInlinedAttachments.append(attachment)
            return nonInlinedAttachments.count - 1
        }

        mutating func add(attachments: [Attachment]) {
            for attachment in attachments {
                nonInlinedAttachments.append(attachment)
            }
        }

        mutating func remove(at index: Int) {
            if index < 0 || index > (nonInlinedAttachments.count - 1) {
                Log.shared.errorAndCrash(component: #function, errorString: "Index out of bounds")
                return
            }
            nonInlinedAttachments.remove(at: index)
        }
    }
}
