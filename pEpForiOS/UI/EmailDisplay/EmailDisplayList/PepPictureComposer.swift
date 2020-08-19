//
//  PepPictureComposer.swift
//  pEp
//
//  Created by Borja González de Pablo on 14/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

class PepProfilePictureComposer: ProfilePictureComposerProtocol {

    let identityImageTool = IdentityImageTool()

    func profilePicture(for identityKey: IdentityImageTool.IdentityKey) -> UIImage? {
        if let image = identityImageTool.cachedIdentityImage(for: identityKey){
            return image
        } else {
            let senderImage = identityImageTool.identityImage(for: identityKey)
            return senderImage
        }
    }
}
