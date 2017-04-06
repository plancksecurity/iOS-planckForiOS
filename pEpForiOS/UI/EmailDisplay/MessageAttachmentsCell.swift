//
//  MessageAttachmentsCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 04.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class MessageAttachmentsCell: MessageCell, AttachmentsViewHelperDelegate {
    @IBOutlet weak var attachmentsImageView: ImageView!
    var attachmentsViewHelper = AttachmentsViewHelper()
    var lastAttachmentsView: UIView?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(
            self, selector: #selector(deviceRotationChanged(notification:)),
            name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }

    func deviceRotationChanged(notification: Notification) {
        if let v = lastAttachmentsView as? ImageView {
            v.change(width: frame.size.width)
        }
    }

    public override func updateCell(model: ComposeFieldModel, message: Message,
                                    indexPath: IndexPath) {
        super.updateCell(model: model, message: message, indexPath: indexPath)
        titleLabel?.text = "Attachments"
        attachmentsViewHelper.delegate = self
        attachmentsViewHelper.attachmentsImageView = attachmentsImageView
        attachmentsViewHelper.message = message
    }

    func update(attachmentsView: UIView?, message: Message) {
        lastAttachmentsView = attachmentsView

        /*
        if let v = attachmentsView {
            let subViews = contentView.subviews
            for sub in subViews {
                sub.removeFromSuperview()
            }
            contentView.addSubview(v)
            (delegate as? MessageContentCellDelegate)?.didUpdate(
                cell: self, height: v.frame.size.height)
        }
         */
    }
}

// MARK: - AttachmentsViewHelperDelegate

extension MessageAttachmentsCell {
    func didCreate(attachmentsView: UIView?, message: Message) {
        GCD.onMain {
            self.update(attachmentsView: attachmentsView, message: message)
        }
    }
}
