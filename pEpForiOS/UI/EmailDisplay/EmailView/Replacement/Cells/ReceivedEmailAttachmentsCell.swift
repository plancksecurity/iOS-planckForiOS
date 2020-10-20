//
//  ReceivedEmailAttachmentsCell.swift
//  pEp
//
//  Created by Martín Brude on 20/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol ReceivedEmailAttachmentsCellViewModel {
    
}

protocol ReceivedEmailAttachmentsCellDelegate: class {
    func didTap()
}

class ReceivedEmailAttachmentsCell : UITableViewCell {
    weak var delegate: ReceivedEmailAttachmentsCellDelegate?
    @IBOutlet weak var attachmentsImageView: AttachmentsView!
    var attachmentsViewHelper = AttachmentsViewHelper()

    public func update(with viewModel: ReceivedEmailAttachmentsCellViewModel) {
        
    }
    
    public func didTap() {
        delegate?.didTap()
    }
}
