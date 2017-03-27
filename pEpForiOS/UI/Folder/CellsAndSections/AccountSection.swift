//
//  AccountSection.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 21/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

public class AccountSection: UITableViewCell {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var accountType: UILabel!
    @IBOutlet weak var accountName: UILabel!
    @IBOutlet weak var userAddress: UILabel!
    @IBOutlet weak var disclosureIndeicator: UILabel!
    @IBOutlet weak var actionView: UIView!

    //var vm : FolderSectionViewModel?
    var section : Int?
    var delegate : TableCollapsableDelegate?

    func configure(section: FolderSectionViewModel, table: TableCollapsableDelegate, sectionNum: Int) {
        self.delegate = table
        //vm = section
        self.section = sectionNum
        //profileImage.image = section.image

                //self.addGestureRecognizer(UITapGestureRecognizer( target: self, action: #selector( self.tapHeader(_:))))
        accountType.text = section.type
        accountName.text = section.userName
        userAddress.text = section.userAddress
    }

    public func tapHeader(gestureRecognizer: UITapGestureRecognizer) {
        /*guard let cell = gestureRecognizer.view as? AccountSection else {
            return
        }*/
            delegate?.toggleSection(section: section!)
    }

    public override func awakeFromNib() {
        super.awakeFromNib()
    }

}

public protocol TableCollapsableDelegate {
    func toggleSection(section: Int)
}
