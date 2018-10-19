//
//  MediaAttachmentPickerViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 19.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol MediaAttachmentPickerProviderViewModelResultDelegate: class {
    func mediaAttachmentPickerProviderViewModel(_ vm: MediaAttachmentPickerProviderViewModel,
                                        didSelect mediaAttachment:
        MediaAttachmentPickerProviderViewModel.MediaAttachment)
}

class MediaAttachmentPickerProviderViewModel {
    weak public var resultDelegate: MediaAttachmentPickerProviderViewModelResultDelegate?

    public init(resultDelegate: MediaAttachmentPickerProviderViewModelResultDelegate?) {
        self.resultDelegate = resultDelegate
    }
}

// MARK: - MediaAttachment

extension MediaAttachmentPickerProviderViewModel {
    struct MediaAttachment {
        enum MediaAttachmentType {
            case photo
            case video
        }
        let type: MediaAttachmentType
        let attachment: Attachment
    }
}
