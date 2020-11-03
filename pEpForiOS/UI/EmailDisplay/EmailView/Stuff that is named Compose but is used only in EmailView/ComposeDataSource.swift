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

    // MARK: - AttachmentDataSource

    struct AttachmentDataSource {
        struct Row {
            let fileName: String?
            let fileExtesion: String?
        }
        public private(set) var attachments = [Attachment]()
        let mimeTypeUtils = MimeTypeUtils()

        func count() -> Int {
            return attachments.count
        }

        subscript(index: Int) -> Row? {
            if index < 0 || index > (attachments.count - 1) {
                Log.shared.errorAndCrash("Index out of bounds")
                return nil
            }
            let attachment = attachments[index]
            let mimeType = attachment.mimeType ?? ""
            return Row(fileName: attachment.fileName,
                       fileExtesion: mimeTypeUtils?.fileExtension(fromMimeType: mimeType) ?? "")
        }

        /// Adds an attachment to the data source and returns the index it has been inserted in.
        ///
        /// - Parameter attachment: attachment to add
        /// - Returns: index the attachment has been inserted in
        @discardableResult mutating func add(attachment: Attachment) -> Int {
            attachments.append(attachment)
            return attachments.count - 1
        }

        /// Removes an attachment from the data source and returns the index
        /// it has been removed from.
        ///
        /// - Parameter attachment: attachment to remove
        /// - Returns: If the attachment was found, the index the attachment has been removed from.
        ///             nil otherwize
        @discardableResult mutating func remove(attachment: Attachment) -> Int? {
            for (index, existingAttachment) in attachments.enumerated() {
                if existingAttachment == attachment {
                    attachments.remove(at: index)
                    return index
                }
            }
            return nil
        }

        mutating func add(attachments: [Attachment]) {
            for attachment in attachments {
                self.attachments.append(attachment)
            }
        }

        mutating func remove(at index: Int) {
            if index < 0 || index > (attachments.count - 1) {
                Log.shared.errorAndCrash("Index out of bounds")
                return
            }
            attachments.remove(at: index)
        }
    }
}
