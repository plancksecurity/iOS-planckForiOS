//
//  RecipientsBannerViewModel.swift
//  pEpForiOS
//
//  Created by Martín Brude on 17/11/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

protocol RecipientsBannerDelegate: AnyObject {

    /// Presents the recipients list view
    /// - Parameters:
    ///   - recipientsListViewModel: The View Model.
    func presentRecipientsListView(recipientsListViewModel: RecipientsListViewModel)
}

class RecipientsBannerViewModel {

    public weak var delegate: RecipientsBannerDelegate?

    private var recipients: [Identity] = []

    init(recipients: [Identity]) {
        self.recipients = recipients
    }

    public var buttonTitle: String {
        let format = NSLocalizedString("$1 unsecure recipients. Click here to review and remove", comment: "")
        let result = String.localizedStringWithFormat(format, recipients.count)
        return result
    }

    /// Handle
    public func handleRecipientsButtonPressed() {
        let recipientsListViewModel = RecipientsListViewModel(recipients: recipients)
        delegate?.presentRecipientsListView(recipientsListViewModel: recipientsListViewModel)
    }
}

