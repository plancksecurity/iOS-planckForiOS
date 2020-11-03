//
//  Identity+IdentityImageUtils.swift
//  MessageModel
//
//  Created by Andreas Buff on 14.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

// MARK: - IdentityImageUtils

extension Identity {

    public func thumbnailImage() -> UIImage? {
        guard let addressBookID = addressBookID else {
            return nil
        }

        let contact = AddressBook.contactBy(addressBookID: addressBookID)

        guard let data = contact?.thumbnailImageData else {
            return nil
        }

        return UIImage(data: data)
    }
}
