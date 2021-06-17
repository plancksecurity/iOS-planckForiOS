//
//  ComposeViewModel+AttachmentSizeUtil.swift
//  pEpForiOS
//
//  Created by Martín Brude on 11/6/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
import pEpIOSToolboxForExtensions
#else
import MessageModel
import pEpIOSToolbox
#endif

extension ComposeViewModel {

    // This util helps to offer the user to reduce the quality and therefore the weight of the images to send.
    // We compress the images, get the new sizes and present them to the user to choose.
    //
    // Easy to use:
    // - Instanciate it
    // - Check if should offer scaling to the user. (shouldOfferScaling)
    // - If so, get the titles to show to the user. (title attributes)
    // - Inform the choosen option and get the attachments scaled, based on the choosen option. (getAttachments...)
    class AttachmentSizeUtil {

        private var session: Session
        private var composeViewModelState: ComposeViewModelState


        private var didFinishSetup = false

        /// The choosen size, actual by default
        private var size = JPEGQuality.highest

        private var numberOfImages: Int = 0

        private var actualAttachments: [Attachment] = []
        private var largeAttachments: [Attachment] = []
        private var mediumAttachments: [Attachment] = []
        private var smallAttachments: [Attachment] = []

        private let inferiorLimit: Double = 500.0

        private var smallAttachmentsSize: Double = 0.0
        private var mediumAttachmentsSize: Double = 0.0
        private var largeAttachmentsSize: Double = 0.0
        private var actualAttachmentsSize: Double = 0.0

        //MARK: - Texts

        /// Action sheet title
        public var title: String {
            var size: Double = 0.0
            session.performAndWait { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                size = me.actualAttachments.size()
            }

            // Plural
            if numberOfImages > 1 {
                return title(with: NSLocalizedString("The attachments of this message are %1$@. You can reduce message size by scaling the images to one of the sizes below", comment: "Reduce attachments size title"), andSize: size)
            }
            return title(with: NSLocalizedString("The attachment of this message is %1$@. You can reduce message size by scaling the image to one of the sizes below", comment: "Reduce attachment size title"), andSize: size)
        }

        /// The title for the small size option
        public var smallSizeTitle: String {
            let format = NSLocalizedString("Small (%1$@)", comment: "Small size action title")
            return title(with: format, andSize: smallAttachmentsSize)
        }

        /// The title for the medium size option
        public var mediumSizeTitle: String {
            let format = NSLocalizedString("Medium (%1$@)", comment: "Medium size action title")
            return title(with: format, andSize: mediumAttachmentsSize)
        }

        /// The title for the large size option
        public var largeSizeTitle: String {
            let format = NSLocalizedString("Large (%1$@)", comment: "Large size action title")
            return title(with: format, andSize: largeAttachmentsSize)
        }

        /// - Returns: The title for the actual size option
        public var actualSizeTitle: String {
            let format = NSLocalizedString("Actual (%1$@)", comment: "Actual size action title")
            return title(with: format, andSize: actualAttachmentsSize)
        }

        //MARK: - Constructor

        /// Constructor
        /// - Parameter session: The session to work on
        public init(session: Session, composeViewModelState: ComposeViewModelState) {
            self.session = session
            self.composeViewModelState = composeViewModelState
        }

        //MARK: - Helpers

        /// Indicates whether the user should choose to scale the images
        /// You MUST pass the attachments using the same session used in the util.
        ///
        /// - Returns: True if it should offer scaling to the user
        public func shouldOfferScaling() -> Bool {
            let safeState = composeViewModelState.makeSafe(forSession: session)
            calculateAndGroupAttachments(inlinedAttachments: safeState.inlinedAttachments,
                                         nonInlinedAttachments: safeState.nonInlinedAttachments)
            var should = false
            session.performAndWait { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                should = me.inferiorLimit < me.actualAttachments.size()
            }
            return should
        }

        /// Get attachments compressed
        /// - Parameters:
        ///   - inlined: Filter the attachments, inlined or not.
        ///   - compressionQuality: The compression quality of the attachments
        /// - Returns: The attachments compressed and filtered.
        /// - Throws: Error if has not yet been set up correctly.
        public func getAttachments(inlined: Bool, compressionQuality: JPEGQuality) throws -> [Attachment] {
            guard didFinishSetup else {
                // This util has not yet been set up correctly.
                throw AttachmentSizeUtilError.invalidState
            }
            var attachments = [Attachment]()
            session.performAndWait { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                switch compressionQuality {
                case .highest:
                    attachments = me.actualAttachments.filter{ $0.isInlined == inlined }
                case .high:
                    attachments = me.largeAttachments.filter{ $0.isInlined == inlined }
                case .medium:
                    attachments = me.mediumAttachments.filter{ $0.isInlined == inlined }
                case .low:
                    attachments = me.smallAttachments.filter{ $0.isInlined == inlined }
                }
            }
            return attachments
        }

        //MARK: -  Private

        private func calculateAndGroupAttachments(inlinedAttachments: [Attachment], nonInlinedAttachments: [Attachment]) {
            var numberOfImages = 0
            var actualAttachments = [Attachment]()
            var smallAttachments = [Attachment]()
            var mediumAttachments = [Attachment]()
            var largeAttachments = [Attachment]()

            session.performAndWait { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                /// Calculate size and organize all attachments in 4 groups: actual (current size), large, medium and small size.
                let attachmentsToCalculateSize = inlinedAttachments + nonInlinedAttachments
                attachmentsToCalculateSize.forEach {  attachment in
                    if attachment.image != nil, let mimeType = attachment.mimeType {
                        numberOfImages += 1
                        // We scale the actual image because we use jpeg compression and the image might have another file extension.
                        if let actual = attachment.image?.jpeg(.highest) {
                            let actualAttachment = me.scaledAttachment(data: actual, mimeType: mimeType, contentDisposition: attachment.contentDisposition)
                            actualAttachments.append(actualAttachment)
                        }
                        if let large = attachment.image?.jpeg(.high) {
                            let largeAttachment = me.scaledAttachment(data: large, mimeType: mimeType, contentDisposition: attachment.contentDisposition)
                            largeAttachments.append(largeAttachment)
                        }
                        if let medium = attachment.image?.jpeg(.medium) {
                            let mediumAttachment = me.scaledAttachment(data: medium, mimeType: mimeType, contentDisposition: attachment.contentDisposition)
                            mediumAttachments.append(mediumAttachment)
                        }
                        if let small = attachment.image?.jpeg(.low) {
                            let smallAttachment = me.scaledAttachment(data: small, mimeType: mimeType, contentDisposition: attachment.contentDisposition)
                            smallAttachments.append(smallAttachment)
                        }
                    }
                }
                me.actualAttachmentsSize = actualAttachments.size()
                me.largeAttachmentsSize = largeAttachments.size()
                me.mediumAttachmentsSize = mediumAttachments.size()
                me.smallAttachmentsSize = smallAttachments.size()
            }
            self.actualAttachments = actualAttachments
            self.largeAttachments = largeAttachments
            self.mediumAttachments = mediumAttachments
            self.smallAttachments = smallAttachments
            self.didFinishSetup = true
        }

        private func title(with format: String, andSize: Double) -> String {
            return String.localizedStringWithFormat(format, ByteCountFormatter.string(fromByteCount: Int64(andSize), countStyle: .file))
        }

        private func scaledAttachment(data: Data, mimeType: String, contentDisposition: Attachment.ContentDispositionType) -> Attachment {
            return Attachment(data: data, mimeType: mimeType, image: UIImage(data: data), contentDisposition: contentDisposition, session: session)
        }
    }
}

//MARK: -  AttachmentSizeUtil Error

public enum AttachmentSizeUtilError: Error {
    case invalidState
}

extension AttachmentSizeUtilError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidState:
            return NSLocalizedString( "This util has not yet been set up correctly. Please consider check if it scaling should be offered first ", comment: "Internal Error Message - Wrong util setup")
        }
    }
}
