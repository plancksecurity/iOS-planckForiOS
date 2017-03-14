//
//  FilterCellViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 13/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public enum FilterCellType {
    case unread, indicate, forMe, forMeCc, attachment
}

public class FilterCellViewModel {

    var account: Account?
    var icon: UIImage?
    var title: String
    var enabled: Bool = false
    var filter: Filter?

    init(account _account: Account, filter _filter: Filter? = nil) {
        self.account = _account
        self.icon = UIImage(named: "folders-icon-inbox")!
        self.title = ""
        if let acc = account {
            self.title = acc.user.address
        }
        filter = _filter
    }

    init(type: FilterCellType, filter _filter: Filter? = nil) {
        filter = _filter
        let circleSize = CGSize(width: 14, height: 14)
        let squareSize = CGSize(width: 20, height: 14)
        switch type {
        case .unread:
            guard let image = FlagImages.create(imageSize: circleSize).notSeenImage else {
                title = ""
                return
            }
            icon = image
            title = NSLocalizedString("Unread", comment: "title unread filter cell")

        case .indicate:
            guard let image = FlagImages.create(imageSize: circleSize).flaggedImage else {
                title = ""
                return
            }
            icon = image
            title = NSLocalizedString("Flagged", comment: "title unread filter cell")

        case .forMe:
            guard let image = FlagImages.create(imageSize: squareSize).toMeImage else {
                self.icon = UIImage(named: "folders-icon-inbox")!
                title = ""
                return
            }
            icon = image
            title = NSLocalizedString("For me", comment: "title unread filter cell")

        case .forMeCc:
            guard let image = FlagImages.create(imageSize: squareSize).toMeCcImage else {
                self.icon = UIImage(named: "folders-icon-inbox")!
                title = ""
                return
            }
            icon = image
            title = NSLocalizedString("For me in copy", comment: "title unread filter cell")

        case .attachment:
            self.icon = UIImage(named: "attachment-list-icon")!
            self.title = NSLocalizedString("Attachments", comment: "title attachments filter cell")
        }
    }
    
}
