//
//  MessageAttachmentsCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 30/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class MessageAttachmentsCell: MessageCell {
    @IBOutlet weak var stackView: UIStackView!

    let boundsKeyPath = "bounds"
    let mimeTypes = MimeTypeUtil()

    open override func awakeFromNib() {
        super.awakeFromNib()
        stackView.addObserver(self, forKeyPath: boundsKeyPath,
                              options: [.new, .old], context: nil)
    }

    deinit {
        stackView.removeObserver(self, forKeyPath: boundsKeyPath)
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                    change: [NSKeyValueChangeKey : Any]?,
                                    context: UnsafeMutableRawPointer?) {
        if keyPath == boundsKeyPath,
            let view = object as? UIStackView,
            view == stackView {
            if let newValue = change?[NSKeyValueChangeKey.newKey] as? CGRect,
                let oldValue = change?[NSKeyValueChangeKey.oldKey] as? CGRect {
                if !oldValue.equalTo(newValue) {
                    let newHeight = newValue.size.height
                    if newHeight != height {
                        height = newHeight
                        (delegate as? MessageContentCellDelegate)?.didUpdate(cell: self,
                                                                             height: height)
                    }
                }
            }
        }
    }

    public override func updateCell(model: ComposeFieldModel, message: Message,
                                    indexPath: IndexPath) {
        super.updateCell(model: model, message: message, indexPath: indexPath)

        removeExistingAttachmentViews()
        let viewCount = addAttachmentViews(message: message)
        if viewCount > 0 {
            height = stackView.bounds.size.height
        } else {
            height = 0
        }
    }

    func removeExistingAttachmentViews() {
        let views = stackView.arrangedSubviews
        for v in views {
            stackView?.removeArrangedSubview(v)
        }
    }

    func addAttachmentViews(message: Message) -> Int {
        let views = gatherAttachmentViews(message: message)
        for v in views {
            stackView?.addArrangedSubview(v)
        }
        return views.count
    }

    func gatherAttachmentViews(message: Message) -> [UIView] {
        var views = [UIView]()
        for att in message.attachments {
            if (mimeTypes?.isImage(mimeType: att.mimeType) ?? false),
                let imgData = att.data {
                let img = UIImage(data: imgData)
                if let theImg = img {
                    let imgView = UIImageView(image: theImg)
                    views.append(imgView)
                }
            } else {
                // TODO: IOS-113 display other attachments
            }
        }
        return views
    }
}
