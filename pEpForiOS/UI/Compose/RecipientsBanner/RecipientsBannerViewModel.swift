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
import pEpIOSToolboxForExtensions
#else
import MessageModel
import pEpIOSToolbox
#endif

protocol RecipientsBannerDelegate: AnyObject {

    /// Presents the recipients list view
    func presentRecipientsListView(viewModel: RecipientsListViewModel)
}

/// This VM handles the banner that appears in the compose view when the user introduces an address of a red identity in a recipient field.
/// Its main responsability is to provide data for the layout and handle the interaction with the single button it has.
class RecipientsBannerViewModel {

    /// Delegate to communicate with the view.
    public weak var delegate: RecipientsBannerDelegate?

    private var recipients: [Identity] = []

    private var composeViewModel: ComposeViewModel

    /// Constructor
    ///
    /// - parameters:
    ///   - recipients: The list of red recipients
    ///   - delegate: The delegate to communicate with the view.
    init?(recipients: [Identity], delegate: RecipientsBannerDelegate, composeViewModel: ComposeViewModel) {
        if recipients.count == 0 {
            return nil
        }
        self.recipients = recipients.uniques
        self.delegate = delegate
        self.composeViewModel = composeViewModel
    }

    /// The button title
    public var buttonTitle: String {
        let numberOfUnsecureRecipients = recipients.count
        var format: String
        // Prepare text considering if it's singular or plural
        if numberOfUnsecureRecipients == 1 {
            format = NSLocalizedString("%d unsecure recipient. Tap here to review and remove", comment: "unsecure recipient button")
        } else {
            format = NSLocalizedString("%d unsecure recipients. Tap here to review and remove", comment: "unsecure recipient button")
        }
        return String.localizedStringWithFormat(format, numberOfUnsecureRecipients)
    }

    /// Handle recipients button was pressed.
    public func handleRecipientsButtonPressed() {
        let recipientsListViewModel = RecipientsListViewModel(recipients: recipients, viewModelDelegate: composeViewModel)
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard let delegate = me.delegate else {
                Log.shared.errorAndCrash("No delegate. Unexpected")
                return
            }
            delegate.presentRecipientsListView(viewModel: recipientsListViewModel)
        }
    }
}
