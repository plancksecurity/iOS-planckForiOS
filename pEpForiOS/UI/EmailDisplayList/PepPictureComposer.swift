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

    func getProfilePicture(for address: Identity, completion: @escaping (UIImage?) -> ()) {

        if let image = self.contactImageTool.cachedIdentityImage(forIdentity: address){
            completion(image)


        } else {
            DispatchQueue.global().async {

                let senderImage = self.contactImageTool.identityImage(for: address)
                DispatchQueue.main.async {
                    completion(senderImage)
                }
            }
        }
    }

    func getSecurityBadge(for message: Message, completion: @escaping (UIImage?) ->()){
        MessageModel.performAndWait {
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
