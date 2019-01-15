//
//  ContentDispositionType + Conversion.swift
//  pEp
//
//  Created by Andreas Buff on 18.04.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension content_disposition_type {

    var contentDisponitionType: Attachment.ContentDispositionType {
        return Attachment.ContentDispositionType(with: self)
    }

    var pantomimeContentDisposition: PantomimeContentDisposition {
        switch self {
        case PEP_CONTENT_DISP_ATTACHMENT:
            return PantomimeAttachmentDisposition
        case PEP_CONTENT_DISP_INLINE:
            return PantomimeInlineDisposition
        case PEP_CONTENT_DISP_OTHER:
            return PantomimeAttachmentDisposition
        default:
            Logger.modelLogger.errorAndCrash("Unknown case")
            return PantomimeAttachmentDisposition
        }
    }

    init(with contentDisponitionType: Attachment.ContentDispositionType) {
        switch contentDisponitionType {
        case .attachment:
            self = PEP_CONTENT_DISP_ATTACHMENT
        case .inline:
            self = PEP_CONTENT_DISP_INLINE
        case .other:
            self = PEP_CONTENT_DISP_OTHER
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

    var pEpAdapterContentDisposition: content_disposition_type {
        return content_disposition_type(rawValue: Int32(self.rawValue))
    }

    init(with pEpAdapterContentDisposition: content_disposition_type) {
        switch pEpAdapterContentDisposition {
        case PEP_CONTENT_DISP_ATTACHMENT:
            self = .attachment
        case PEP_CONTENT_DISP_INLINE:
            self = .inline
        case PEP_CONTENT_DISP_OTHER:
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
