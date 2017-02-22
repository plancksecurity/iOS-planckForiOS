//
//  Folder+Extensions.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 22/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit
import MessageModel

extension FolderType {
    public func getIconType() -> UIImage {
        switch self {
        case .normal:
            if let image = UIImage(named: "folders-icon-folder") {
                return image
            }
            break
        case .archive:
            if let image = UIImage(named: "folders-icon-archive") {
                return image
            }
            break
        case .drafts:
            if let image = UIImage(named: "folders-icon-draft") {
                return image
            }
            break
        case .inbox:
            if let image = UIImage(named: "folders-icon-inbox") {
                return image
            }
            break
        case .sent:
            if let image = UIImage(named: "folders-icon-sent") {
                return image
            }
            break
        case .trash:
            if let image = UIImage(named: "folders-icon-trash") {
                return image
            }
            break
        case .spam:
            if let image = UIImage(named: "folders-icon-junk") {
                return image
            }
            break
        default:
            break
        }
        return UIImage()
    }
}
