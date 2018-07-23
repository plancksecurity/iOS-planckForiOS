//
//  ProfilePictureRetriever.swift
//  pEp
//
//  Created by Borja González de Pablo on 14/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

protocol ProfilePictureComposer {

    func getProfilePicture(for address: Identity, completion: @escaping (UIImage?)->())

    func getSecurityBadge(for message: Message, completion: @escaping (UIImage?) ->())

}
