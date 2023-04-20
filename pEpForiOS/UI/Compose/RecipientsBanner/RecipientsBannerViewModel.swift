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

/// This VM handles the banner that appears in the compose view when the user introduces an address of a red identity
/// in a recipient field.
/// Its main responsability is to provide data for the layout, and handle the interaction with the single button it has
/// to remove them from compose view.
class RecipientsBannerViewModel {

    /// Flag used to guarantee there are no update regarding the banner while removing unsecure recipeints
    var canUpdate: Bool = true

    private var recipients: [Identity] = []

    private var composeViewModel: ComposeViewModel

    /// Constructor
    ///
    /// - parameters:
    ///   - composeViewModel: The ComposeViewModel
    init(composeViewModel: ComposeViewModel) {
        self.recipients = recipients.uniques
        self.composeViewModel = composeViewModel
    }

    func setRecipients(recipients: [Identity]) {
        self.recipients = recipients
    }
 
    /// The button title
    public var buttonTitle: String {
        let numberOfUnsecureRecipients = recipients.count
        var format: String
        // Prepare text considering if it's singular or plural
        if numberOfUnsecureRecipients == 1 {
            format = NSLocalizedString("%d unsecure recipient. Tap here to remove.",
                                       comment: "unsecure recipient button")
        } else {
            format = NSLocalizedString("%d unsecure recipients. Tap here to remove.",
                                       comment: "unsecure recipient button")
        }
        return String.localizedStringWithFormat(format, numberOfUnsecureRecipients)
    }

    /// Handle recipients button was pressed.
    public func handleRecipientsButtonPressed() {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.canUpdate = false
            me.composeViewModel.removeFromState(addresses: me.recipients.map { $0.address} )
            me.canUpdate = true
            me.composeViewModel.delegate?.hideRecipientsBanner()
        }
    }
}
