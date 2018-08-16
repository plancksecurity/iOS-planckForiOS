//
//  ComposeFieldModel.swift
//
//  Created by Igor Vojinovic on 11/3/16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import Foundation
import UIKit

public class ComposeFieldModel {
    public enum FieldType: String {
        case to, cc, bcc, from, subject, content, mailingList, none, attachment, wraped

        func translatedTitle(expanded: Bool = false) -> String {
            switch self {
            case .to:
                return NSLocalizedString("To:", comment: "Compose field title")
            case .cc:
                return NSLocalizedString("CC:", comment: "Compose field title")
            case .bcc:
                return NSLocalizedString("BCC:", comment: "Compose field title")
            case .wraped:
                return NSLocalizedString("Cc/Bcc:", comment: "Compose field title")
            case .from:
                return NSLocalizedString("From:", comment: "Compose field title")
            case .subject:
                return NSLocalizedString("Subject:", comment: "Compose field title")
            case .mailingList:
                return NSLocalizedString("This message is from a mailing list.",
                                         comment: "Compose field title")
            default:
                return ""
            }
        }
    }
    
    enum FieldDisplayType: String {
        case always, conditional, never
    }
    
    var type: FieldType = .to
    var display: FieldDisplayType = .always
    var height: CGFloat = defaultCellHeight
    var expanded: CGFloat = 0
    var identifier = "recipientCell"
    var title = String()
    var expandedTitle: String?
    var value = NSAttributedString()
    var contactSuggestion = false
    
    init(with data: [String: Any]) {
        type = FieldType(rawValue: (data["type"] as? String)!) ?? .none
        title = type.translatedTitle()
        expandedTitle = type.translatedTitle(expanded: true)
        display = FieldDisplayType(rawValue: data["visible"] as! String)!
        height = CGFloat((data["height"] as! NSString).floatValue)
        identifier = data["identifier"] as! String
        contactSuggestion = data["contactSuggestion"] as? Bool ?? false
        
        if let expandable = data["expanded"] as? NSString {
            expanded = CGFloat(expandable.floatValue)
        }
    }
}

extension ComposeFieldModel: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "<ComposeFieldModel \(type) \(display) \(height) \(expanded) \(identifier) \(title)>"
    }
}
