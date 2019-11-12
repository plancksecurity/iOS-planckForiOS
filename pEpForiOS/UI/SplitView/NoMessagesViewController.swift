//
//  NoMessagesViewController.swift
//  pEp
//
//  Created by Borja González de Pablo on 25/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class NoMessagesViewController: UIViewController {
    @IBOutlet weak var labelMessage: UILabel!

    /// The message to display when this VC is shown in the details view.
    /// - Note: On some devices, the master VC has no chance to decide for this message
    ///   in all circunstances, unless involving more support code,
    ///   so this default should be neutral enough to cover all views that need it.
    var message: String = NSLocalizedString(
        "Nothing Selected",
        comment: "Default message in detail view when nothing has been selected")

    override func viewWillAppear(_ animated: Bool) {
        updateView()
    }

    /// Call this if you changed the message.
    func updateView() {
        labelMessage.text = message
    }
}
