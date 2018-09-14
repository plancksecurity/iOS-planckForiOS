//
//  PepPictureComposer.swift
//  pEp
//
//  Created by Borja González de Pablo on 14/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

class PepProfilePictureComposer: ProfilePictureComposer {

    let contactImageTool = IdentityImageTool()

    func profilePicture(for identity: Identity, completion: @escaping (UIImage?) -> ()) {
        if let image = self.contactImageTool.cachedIdentityImage(forIdentity: identity){
            completion(image)
        } else {
            DispatchQueue.global(qos: .userInitiated).async{
                let senderImage = self.contactImageTool.identityImage(for: identity)
                DispatchQueue.main.async {
                    completion(senderImage)
                }
            }
        }
    }

    func securityBadge(for message: Message, completion: @escaping (UIImage?) ->()){
        DispatchQueue.global(qos: .userInitiated).async{
            let color = PEPUtil.pEpColor(pEpRating: message.pEpRating())
            var image: UIImage? = nil
            if color != PEP_color_no_color {
                image = color.statusIcon()
            }
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}
