//
//  ProfilePictureRetriever.swift
//  pEp
//
//  Created by Borja González de Pablo on 14/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

protocol ProfilePictureComposer { //!!!: BUFF: remnamen (xyzProtocol)
    /**
     Retrieves a profile picture (if any) for the given identity.
     */
    func profilePicture(for identityKey: IdentityImageTool.IdentityKey,
                        completion: @escaping (UIImage?) -> ())

    /**
     Retrieves a status icon matching the status of the given message.
     */
    func securityBadge(for message: Message, completion: @escaping (UIImage?) -> ())

}
