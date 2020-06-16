//
//  ContactCell.swift
//  pEpForiOS
//

//  Created by Yves Landert on 24.11.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit
import MessageModel

final class ContactCell: UITableViewCell {
    static let reuseId = "ContactCell"

    @IBOutlet weak private var pEpStatusImageView: UIImageView!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var emailLabel: UILabel!

    private let colon = ":"
    
    var contact: Identity? {
        didSet {
            nameLabel.text = contact?.displayString ?? String()
        }
    }

    func updateCell(name: String = "",
                    email: String = "") {
        nameLabel.text = name.isEmpty
            ? name
            : name + colon
        emailLabel.text = email
        getPepStatus(email: email)
    }

    func getPepStatus(email: String) {
        DispatchQueue.main.async { [weak self] in
            // TODO: - ak IOS-1275 from address (get address from ComposeViewModel)
            let pEpRating = SuggestViewModel.calculatePepRating(from: Identity(address: "iostest017@peptest.ch"), to: [Identity(address: email)], cc: [], bcc: [])
            let pEpRatingIcon = pEpRating.pEpColor().statusIconInContactPicture()
            self?.pEpStatusImageView.image = pEpRatingIcon
        }
    }
}
