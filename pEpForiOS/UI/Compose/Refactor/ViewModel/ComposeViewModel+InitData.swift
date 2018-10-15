//
//  ComposeViewModel+InitData.swift
//  pEp
//
//  Created by Andreas Buff on 15.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

// MARK: - InitData

//IOS-1369: wrap in extention when done to not polute the namespace
//extension ComposeViewModel {
    /// Wraps properties used for initial setup
    struct InitData {
        /// Recipient to set as "To:".
        /// Is ignored if a originalMessage is set.
        public let prefilledTo: Identity?
        /// Original message to compute content and recipients from (e.g. a message we reply to).
        public let originalMessage: Message?

        public let composeMode: ComposeUtil.ComposeMode

        /// Whether or not the original message is in Drafts or Outbox
        var isDraftsOrOutbox: Bool {
            return isDrafts || isOutbox
        }

        /// Whether or not the original message is in Drafts folder
        var isDrafts: Bool {
            if let om = originalMessage {
                return om.parent.folderType == .drafts
            }
            return false
        }

        /// Whether or not the original message is in Outbox
        var isOutbox: Bool {
            if let om = originalMessage {
                return om.parent.folderType == .outbox
            }
            return false
        }

        var from: Identity? {
            return ComposeUtil.initialFrom(composeMode: composeMode,
                                           originalMessage: originalMessage)
        }

        var toRecipients: [Identity] {
            if let om = originalMessage {
                return ComposeUtil.initialTos(composeMode: composeMode, originalMessage: om)
            } else if let presetTo = prefilledTo {
                return [presetTo]
            }
            return []
        }

        var ccRecipients: [Identity] {
            guard let om = originalMessage else {
                return []
            }
            return ComposeUtil.initialCcs(composeMode: composeMode, originalMessage: om)
        }

        var bccRecipients: [Identity] {
            guard let om = originalMessage else {
                return []
            }
            return ComposeUtil.initialBccs(composeMode: composeMode, originalMessage: om)
        }

        var subject: String? {
            return originalMessage?.shortMessage
        }

        //IOS-1369: body needs before 9pm brain

        var nonInlinedAttachments: [Attachment] {
            return ComposeUtil.initialNonInlinedAttachments(composeMode: composeMode,
                                                            originalMessage: originalMessage)
        }



        init(withPrefilledToRecipient prefilledTo: Identity? = nil,
             orForOriginalMessage om: Message? = nil,
             composeMode: ComposeUtil.ComposeMode? = nil) {
            self.composeMode = composeMode ?? ComposeUtil.ComposeMode.normal
            self.originalMessage = om
            self.prefilledTo = om == nil ? prefilledTo : nil
        }
    }
//}
