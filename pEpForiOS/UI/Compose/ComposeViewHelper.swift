//
//  ComposeViewHelper.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/09/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

open class ComposeViewHelper {
    /**
     Builds a pEp mail dictionary from all the related views. This is just a quick
     method for checking the pEp color rating, it's not exhaustive!
     */
    open static func pepMailFromViewForCheckingRating(_ vc: ComposeViewController) -> PEPMessage? {
        var message = PEPMessage()
        for (_, cell) in vc.recipientCells {
            let tf = cell.recipientTextView
            if let text = tf?.text {
                let mailStrings0 = text.removeLeadingPattern(vc.leadingPattern)
                if !mailStrings0.isOnlyWhiteSpace() {
                    let mailStrings1 = mailStrings0.components(
                        separatedBy: vc.recipientStringDelimiter).map() {
                            $0.trimmedWhiteSpace()
                    }

                    let mailStrings2 = mailStrings1.filter() {
                        !$0.isOnlyWhiteSpace()
                    }
                    let contacts: [PEPIdentity] = mailStrings2.map() {
                        if let c = Identity.by(address: $0) {
                            return PEPUtil.pEp(identity: c)
                        }
                        return PEPUtil.pEpIdentity(email: $0, name: $0.namePartOfEmail())
                    }
                    if contacts.count > 0 {
                        if let rt = cell.recipientType {
                            var pepKey: String? = nil
                            switch rt {
                            case .to:
                                pepKey = kPepTo
                            case .cc:
                                pepKey = kPepCC
                            case .bcc:
                                pepKey = kPepBCC
                            }
                            if let key = pepKey {
                                message[key] = NSArray.init(array: contacts)
                            }
                        }
                    }
                }
            }
        }

        guard let account = vc.appConfig?.currentAccount else {
            Log.warn(component: vc.comp, "Need valid account for determining pEp rating")
            return nil
        }
        message[kPepFrom] = PEPUtil.pEp(identity: account.user) as AnyObject?

        if let subjectText = vc.subjectTextField?.text {
            message[kPepShortMessage] = subjectText as AnyObject?
        }
        if let bodyText = vc.longBodyMessageTextView?.text {
            message[kPepLongMessage] = bodyText as AnyObject?
        }
        message[kPepOutgoing] = NSNumber.init(booleanLiteral: true)
        return message
    }

    open static func currentRecipientRangeFromText(
        _ text: NSString, aroundCaretPosition: Int) -> NSRange? {
        let comma: UnicodeScalar = ","
        let colon: UnicodeScalar = ":"
        var start = -1
        var end = -1

        // We want the character that just was changed "under the cursor"
        let location = aroundCaretPosition - 1

        var maxIndex = text.length
        if maxIndex == 0 {
            return nil
        }

        maxIndex = maxIndex - 1

        if location > maxIndex {
            return nil
        }

        var index = location

        // Check if the user just entered a comma or colon. If yes, that's it.
        let ch = text.character(at: index)
        if UInt32(ch) == comma.value || UInt32(ch) == colon.value {
            return nil
        }

        // find beginning
        while true {
            if index < 0 {
                start = 0
                break
            }
            let ch = text.character(at: index)
            if UInt32(ch) == comma.value || UInt32(ch) == colon.value {
                start = index + 1
                break
            }
            index = index - 1
        }

        // find end
        index = location
        while true {
            if index >= maxIndex {
                end = maxIndex + 1
                break
            }
            let ch = text.character(at: index)
            if UInt32(ch) == comma.value {
                end = index
                break
            }
            index = index + 1
        }

        if end != -1 && start != -1 {
            let r = NSRange.init(location: start, length: end - start)
            if r.location >= 0 && r.location + r.length <= text.length {
                return r
            }
        }

        return nil
    }

    /**
     Tries to determine the currently edited part in a recipient text, given the
     text and the last known caret position.
     */
    open static func extractRecipientFromText(
        _ text: NSString, aroundCaretPosition: Int) -> String? {
        if let r = self.currentRecipientRangeFromText(
            text, aroundCaretPosition: aroundCaretPosition) {
            return text.substring(with: r).trimmedWhiteSpace()
        }
        return nil
    }

    /**
     * Puts the emails from the contacts into a recipient text field.
     */
    open static func transfer(
        identities: [Identity], toTextField textField: UITextView, titleText: String?) {
        textField.text = "\(String.orEmpty(titleText))"
        for c in identities {
            textField.text = "\(textField.text)\(c.address), "
        }
    }

    /**
     - Returns: The array of `Contact`s for a given recipient type and message.
     */
    open static func contactsForRecipientType(
        _ recipientType: RecipientType?, fromMessage message: Message) -> [Identity] {
        guard let rt = recipientType else {
            return []
        }
        switch rt {
        case .to:
            return message.to
        case .cc:
            return message.cc
        case .bcc:
            return message.bcc
        }
    }

    /**
     Converts an `NSOrderedSet` into an array of `Contact`.
     Putting this into a function prevents a compiler crash with Swift 2.2 that
     occurs when putting this inline.
     */
    open static func orderedSetToContacts(_ theSet: NSOrderedSet) -> [CdIdentity] {
        return theSet.map({ $0 as! CdIdentity })
    }
}

public extension UIViewController {
    /**
     Return the correct container rectangle for a giving width to maintain the aspect ratio.
     - Returns: The new container rectangle.
     */
    public func obtainContainerToMaintainRatio(_ fixedWidth: CGFloat, rectangle: CGSize) -> CGRect {
        let fixRatio = rectangle.width / rectangle.height
        let newHeight = fixedWidth / fixRatio
        return CGRect(x: 0, y: 0, width: fixedWidth, height: newHeight)
    }
}
