//
//  Message+SecurityBadge.swift
//  pEp
//
//  Created by Andreas Buff on 20.09.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Message {

    /// Retrieves a status icon matching the status of the given message.
    func securityBadgeForContactPicture(completion: @escaping (UIImage?)->Void) {
        pEpRating { (rating) in
            let color = rating.pEpColor()
            var image: UIImage? = nil
            if color != .noColor {
                image = color.statusIconInContactPicture()
            }
            completion(image)
        }
    }
}
