//
//  ContentDispositionType+Conversion.swift
//  pEp
//
//  Created by Andreas Buff on 18.04.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import PEPObjCAdapterFramework
import PantomimeFramework
import pEpIOSToolbox

extension PEPContentDisposition {
    var contentDisponitionType: Attachment.ContentDispositionType {
        return Attachment.ContentDispositionType(with: self)
    }

    var pantomimeContentDisposition: PantomimeContentDisposition {
        switch self {
        case .attachment:
            return PantomimeAttachmentDisposition
        case .inline:
            return PantomimeInlineDisposition
        case .other:
            return PantomimeAttachmentDisposition
    }

    init(with contentDisponitionType: Attachment.ContentDispositionType) {
        switch contentDisponitionType {
        case .attachment:
            self = .attachment
        case .inline:
            self = .inline
        case .other:
            self = .other
        }
    }
}

extension Attachment.ContentDispositionType {
    var pantomimeContentDisposition: PantomimeContentDisposition {
        switch self {
        case .attachment:
            return PantomimeAttachmentDisposition
        case .inline:
            return PantomimeInlineDisposition
        case .other:
            Log.shared.errorAndCrash("Attachment disposition: other")
            return PantomimeAttachmentDisposition
        }
    }

    var pEpAdapterContentDisposition: PEPContentDisposition {
        switch self {
        case .attachment:
            return PEPContentDisposition.attachment
        case .inline:
            return PEPContentDisposition.inline
        case .other:
            Log.shared.errorAndCrash("Attachment disposition: other")
            return PEPContentDisposition.attachment
        }
    }

    init(with pEpAdapterContentDisposition: PEPContentDisposition) {
        switch pEpAdapterContentDisposition {
        case .attachment:
            self = .attachment
        case .inline:
            self = .inline
        case .other:
            self = .attachment // This is probably wrong. Semantic of other not clear
    }

    init(with pantomimeContentDisposition: PantomimeContentDisposition) {
        switch pantomimeContentDisposition {
        case PantomimeAttachmentDisposition:
            self = .attachment
        case PantomimeInlineDisposition:
            self = .inline
        default:
            Log.shared.errorAndCrash("Unknown case")
            self = .attachment
        }
    }
}
