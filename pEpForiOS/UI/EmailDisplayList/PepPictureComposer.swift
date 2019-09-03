//
//  PepPictureComposer.swift
//  pEp
//
//  Created by Borja González de Pablo on 14/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import PEPObjCAdapterFramework

class PepProfilePictureComposer: ProfilePictureComposerProtocol {

    let contactImageTool = IdentityImageTool()

    func profilePicture(for identityKey: IdentityImageTool.IdentityKey) -> UIImage? {
        if let image = contactImageTool.cachedIdentityImage(for: identityKey){
            return image
        } else {
            let senderImage = contactImageTool.identityImage(for: identityKey)
            return senderImage
        }
    }

    func securityBadge(for message: Message) -> UIImage? {
        let color = PEPUtils.pEpColor(pEpRating: message.pEpRating())
        var image: UIImage? = nil
        if color != PEPColor.noColor {
            image = color.statusIconInContactPicture()
        }
        return image
    }
}
