//
//  ContentDispositionType + Conversion.swift
//  pEp
//
//  Created by Andreas Buff on 18.04.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox

extension PEPContentDisposition {
    var contentDisponitionType: Attachment.ContentDispositionType {
        return Attachment.ContentDispositionType(with: self)
    }

    var pantomimeContentDisposition: PantomimeContentDisposition {
        switch self {
        case PEPContentDispAttachment:
            return PantomimeAttachmentDisposition
        case PEPContentDispInline:
            return PantomimeInlineDisposition
        case PEPContentDispOther:
            return PantomimeAttachmentDisposition
        default:
            Logger.modelLogger.errorAndCrash("Unknown case")
            return PantomimeAttachmentDisposition
        }
    }

    init(with contentDisponitionType: Attachment.ContentDispositionType) {
        switch contentDisponitionType {
        case .attachment:
            self = PEPContentDispAttachment
        case .inline:
            self = PEPContentDispInline
        case .other:
            self = PEPContentDispOther
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
        default:
            Logger.modelLogger.errorAndCrash("Unknown case")
            return PantomimeAttachmentDisposition
        }
    }

    var pEpAdapterContentDisposition: PEPContentDisposition {
        return PEPContentDisposition(rawValue: Int32(self.rawValue))
    }

    init(with pEpAdapterContentDisposition: PEPContentDisposition) {
        switch pEpAdapterContentDisposition {
        case PEPContentDispAttachment:
            self = .attachment
        case PEPContentDispInline:
            self = .inline
        case PEPContentDispOther:
            self = .attachment // This is probably wrong. Semantic of other not clear
        default:
            Logger.modelLogger.errorAndCrash("Unknown case")
            self = .attachment
        }
    }

    init(with pantomimeContentDisposition: PantomimeContentDisposition) {
        switch pantomimeContentDisposition {
        case PantomimeAttachmentDisposition:
            self = .attachment
        case PantomimeInlineDisposition:
            self = .inline
        default:
            Logger.modelLogger.errorAndCrash("Unknown case")
            self = .attachment
        }
    }
}
