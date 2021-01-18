//
//  CdAttachment+Pantomime.swift
//  pEp
//
//  Created by Andreas Buff on 17.04.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import PantomimeFramework

// CONTENT DISPOSITION

extension CdAttachment {
    static func contentDispositionRawValue(from
        pantomimeContentDisposition: PantomimeContentDisposition) -> Int16 {
        
        return Attachment.ContentDispositionType(with: pantomimeContentDisposition).rawValue
    }
}
