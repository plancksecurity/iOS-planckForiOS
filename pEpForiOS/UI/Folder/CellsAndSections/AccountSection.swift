//
//  AccountSection.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 21/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

public class AccountSection: UIView {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var accountType: UILabel!
    @IBOutlet weak var accountName: UILabel!
    @IBOutlet weak var userAddress: UILabel!
    @IBOutlet weak var disclousireIndicator: UIImageView!

    func configure(section: FolderSectionViewModel) {
        profileImage.image = section.image
        accountType.text = section.type
        accountName.text = section.userName
        userAddress.text = section.userAddress
        //disclousireIndicator.image =
    }
}
