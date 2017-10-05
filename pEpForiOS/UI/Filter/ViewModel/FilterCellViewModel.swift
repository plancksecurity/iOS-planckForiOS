//
//  FilterCellViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 13/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

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
    }

    init(type: FilterType, filter _filter: Filter? = nil) {
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
            enabled = filter?.ofType(type: .unread) ?? false
            filter = Filter.unread()

        case .flagged:
            guard let image = FlagImages.create(imageSize: circleSize).flaggedImage else {
                title = ""
                return
            }
            icon = image
            title = NSLocalizedString("Flagged", comment: "title unread filter cell")
            enabled = filter?.ofType(type: .flagged) ?? false
            filter = Filter.flagged()

        case .attachment:
            self.icon = UIImage(named: "attachment-list-icon")!
            self.title = NSLocalizedString("Attachments", comment: "title attachments filter cell")
            enabled = filter?.ofType(type: .attachment) ?? false
            filter = Filter.attachment()

        default:
            self.icon = FlagImages.create(imageSize: squareSize).notSeenImage
            self.title = ""
        }
    }

    func getFilter() -> Filter? {
        if enabled {
            return filter ?? nil
        }
        return nil
    }

    func getInvalidFilter() -> Filter? {
        if !enabled {
            return filter
        }
        return nil
    }

}
