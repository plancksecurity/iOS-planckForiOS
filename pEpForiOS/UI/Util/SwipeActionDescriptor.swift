//
//  SwipeActionDescriptor.swift
//  pEp
//
//  Created by Andreas Buff on 30.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

/**
 Swipe configuration.
 */
enum SwipeActionDescriptor {
    case read, unread, reply, more, flag, unflag, trash, archive

    func title(forDisplayMode displayMode: ButtonDisplayMode) -> String? {
        if displayMode == .imageOnly {
            return nil
        }

        switch self {
        case .read:
            return NSLocalizedString("Read",
                                     comment: "'Read' button in slide-left menu. Note: Very little screen space, please keep this one (short) word.")
        case .unread:
            return NSLocalizedString("Unread",
                                     comment: "'Unread' button in slide-left menu. Note: Very little screen space, please keep this one (short) word.")
        case .reply:
            return NSLocalizedString("Reply",
                                     comment: "'Read' button in slide-left menu. Note: Very little screen space, please keep this one (short) word.")
        case .more:
            return NSLocalizedString("More",
                                     comment: "'More' button in slide-left menu. Note: Very little screen space, please keep this one (short) word.")
        case .flag:
            return NSLocalizedString("Flag",
                                     comment: "'Flag' button in slide-left menu. Note: Very little screen space, please keep this one (short) word.")
        case .unflag:
            return NSLocalizedString("Unflag",
                                     comment: "'Unflag' button in slide-left menu. Note: Very little screen space, please keep this one (short) word.")
        case .trash:
            return NSLocalizedString("Trash",
                                     comment: "'Trash' button in slide-left menu. Note: Very little screen space, please keep this one (short) word.")
        case .archive:
            return NSLocalizedString("Archive",
                                     comment: "'Archive' button in slide-left menu. Note: Very little screen space, please keep this one (short) word.")
        
        }
    }

    func image(forStyle style: ButtonStyle, displayMode: ButtonDisplayMode) -> UIImage? {
        if displayMode == .titleOnly {
            return nil
        }

        let name: String
        switch self {
        case .read: name = "read"
        case .unread: name = "unread"
        case .reply: name = "reply"
        case .more: name = "more"
        case .flag: name = "flag"
        case .unflag: name = "flag"
        case .trash: name = "trash"
        case .archive: name = "archive"
        }

        return UIImage(named: "swipe-" + name + (style == .backgroundColor ? "" : "-circle"))
    }

    var color: UIColor {
        let primary = UIColor.primary()

        switch self {
        case .read: return #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        case .reply: return #colorLiteral(red: 0.2980392157, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
        case .unread: return #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        case .more: return #colorLiteral(red: 0.7803494334, green: 0.7761332393, blue: 0.7967314124, alpha: 1)
        case .flag: return #colorLiteral(red: 1, green: 0.5803921569, blue: 0, alpha: 1)
        case .unflag: return #colorLiteral(red: 1, green: 0.5803921569, blue: 0, alpha: 1)
        case .trash: return #colorLiteral(red: 1, green: 0.2352941176, blue: 0.1882352941, alpha: 1)
        case .archive: return primary
        }
    }
}

enum ButtonDisplayMode {
    case titleAndImage, titleOnly, imageOnly
}

enum ButtonStyle {
    case backgroundColor, circular
}
