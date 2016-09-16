//
//  ComposeViewHelper.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/09/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public class ComposeViewHelper {
    /**
     Builds a pEp mail dictionary from all the related views. This is just a quick
     method for checking the pEp color rating, it's not exhaustive!
     */
    public static func pepMailFromViewForCheckingRating(vc: ComposeViewController) -> PEPMail? {
            var message = PEPMail()
            for (_, cell) in vc.recipientCells {
                let tf = cell.recipientTextView
                if let text = tf.text {
                    let mailStrings0 = text.removeLeadingPattern(vc.leadingPattern)
                    if !mailStrings0.isOnlyWhiteSpace() {
                        let mailStrings1 = mailStrings0.componentsSeparatedByString(
                            vc.recipientStringDelimiter).map() {
                                $0.trimmedWhiteSpace()
                        }

                        let mailStrings2 = mailStrings1.filter() {
                            !$0.isOnlyWhiteSpace()
                        }
                        let model = vc.appConfig?.model
                        let contacts: [PEPContact] = mailStrings2.map() {
                            if let c = model?.contactByEmail($0) {
                                return PEPUtil.pepContact(c)
                            }
                            return PEPUtil.pepContactFromEmail($0, name: $0.namePartOfEmail())
                        }
                        if contacts.count > 0 {
                            if let rt = cell.recipientType {
                                var pepKey: String? = nil
                                switch rt {
                                case .To:
                                    pepKey = kPepTo
                                case .CC:
                                    pepKey = kPepCC
                                case .BCC:
                                    pepKey = kPepBCC
                                }
                                if let key = pepKey {
                                    message[key] = contacts
                                }
                            }
                        }
                    }
                }
            }

            guard let account = vc.appConfig?.currentAccount else {
                Log.warnComponent(vc.comp, "Need valid account for determining pEp rating")
                return nil
            }
            message[kPepFrom] = PEPUtil.pepContactFromEmail(
                account.email, name: account.nameOfTheUser)

            if let subjectText = vc.subjectTextField?.text {
                message[kPepShortMessage] = subjectText
            }
            if let bodyText = vc.longBodyMessageTextView?.text {
                message[kPepLongMessage] = bodyText
            }
            message[kPepOutgoing] = true
            return message
    }

    public static func currentRecipientRangeFromText(
        text: NSString, aroundCaretPosition: Int) -> NSRange? {
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
        let ch = text.characterAtIndex(index)
        if UInt32(ch) == comma.value || UInt32(ch) == colon.value {
            return nil
        }

        // find beginning
        while true {
            if index < 0 {
                start = 0
                break
            }
            let ch = text.characterAtIndex(index)
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
            let ch = text.characterAtIndex(index)
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
    public static func extractRecipientFromText(
        text: NSString, aroundCaretPosition: Int) -> String? {
        if let r = self.currentRecipientRangeFromText(
            text, aroundCaretPosition: aroundCaretPosition) {
            return text.substringWithRange(r).trimmedWhiteSpace()
        }
        return nil
    }

    /**
     * Puts the emails from the contacts into a recipient text field.
     */
    public static func transferContacts(
        contacts: [IContact], toTextField textField: UITextView, titleText: String?) {
        textField.text = "\(String.orEmpty(titleText))"
        for c in contacts {
            textField.text = "\(textField.text)\(c.email), "
        }
    }

    /**
     - Returns: The array of `IContact`s for a given recipient type and message.
     */
    public static func contactsForRecipientType(
        recipientType: RecipientType?, fromMessage message: IMessage) -> [IContact] {
        guard let rt = recipientType else {
            return []
        }
        switch rt {
        case .To:
            return orderedSetToContacts(message.to)
        case .CC:
            return orderedSetToContacts(message.cc)
        case .BCC:
            return orderedSetToContacts(message.bcc)
        }
    }

    /**
     Converts an `NSOrderedSet` into an array of `IContact`.
     Putting this into a function prevents a compiler crash with Swift 2.2 that
     occurs when putting this inline.
     */
    public static func orderedSetToContacts(theSet: NSOrderedSet) -> [IContact] {
        return theSet.map({ $0 as! IContact })
    }
}

public extension UIViewController {
    /**
     Return the correct container rectangle for a giving width to maintain the aspect ratio.
     - Returns: The new container rectangle.
     */
    public func obtainContainerToMaintainRatio(fixedWidth: CGFloat, rectangle: CGSize) -> CGRect {
        let fixRatio = rectangle.width / rectangle.height
        let newHeight = fixedWidth / fixRatio
        return CGRect(x: 0, y: 0, width: fixedWidth, height: newHeight)
    }
}