//
//  ProfilePictureRetriever.swift
//  pEp
//
//  Created by Borja González de Pablo on 14/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

protocol ProfilePictureComposerProtocol {

    /// Retrieves a profile picture (if any) for the given identity.
    ///
    /// - note: This is an expensive operation! Do NOT call this on the main queue.
    ///
    /// - Parameter identityKey: data to compute profile picture for
    /// - Returns: profile image if we were able to compute one, nil otherwize
    func profilePicture(for identityKey: IdentityImageTool.IdentityKey) -> UIImage?

    /// Retrieves a status icon matching the status of the given message.
    ///
    /// - note: This is an expensive operation! Do NOT call this on the main queue.
    ///
    /// - Parameters:
    ///   - message: message to get badge for
    /// - Returns: pEp security badge image
    func securityBadge(for message: Message) -> UIImage?
}
