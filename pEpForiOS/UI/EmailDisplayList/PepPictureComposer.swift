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

    func profilePicture(for identityKey: IdentityImageTool.IdentityKey,
                        completion: @escaping (UIImage?) -> ()) {
        if let image = contactImageTool.cachedIdentityImage(for: identityKey){
            DispatchQueue.main.async {
                completion(image)
            }
        } else {
            DispatchQueue.global(qos: .userInitiated).async{ [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                let senderImage = me.contactImageTool.identityImage(for: identityKey)
                DispatchQueue.main.async {
                    completion(senderImage)
                }
            }
        }
    }

    func securityBadge(for message: Message, completion: @escaping (UIImage?) ->()){
        let session = Session()
        let safeMsg = message.safeForSession(session)
        DispatchQueue.global(qos: .userInitiated).async {
            session.performAndWait {
                let color = PEPUtils.pEpColor(pEpRating: safeMsg.pEpRating())
                var image: UIImage? = nil
                if color != PEPColor.noColor {
                    image = color.statusIconInContactPicture()
                }
                completion(image)
            }
        }
    }
}
