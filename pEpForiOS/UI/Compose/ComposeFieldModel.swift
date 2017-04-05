//
//  ComposeFieldModel.swift
//
//  Created by Igor Vojinovic on 11/3/16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import Foundation
import UIKit

open class ComposeFieldModel {
    
    enum FieldType: String {
        case to, cc, bcc, from, subject, content, mailingList, none
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
        title = (data["title"] as! String).localized
        expandedTitle = (data["titleExpanded"] as? String)?.localized
        display = FieldDisplayType(rawValue: data["visible"] as! String)!
        height = CGFloat((data["height"] as! NSString).floatValue)
        identifier = data["identifier"] as! String
        contactSuggestion = data["contactSuggestion"] as? Bool ?? false
        
        if let expandable = data["expanded"] as? NSString {
            expanded = CGFloat(expandable.floatValue)
        }
    }
}
