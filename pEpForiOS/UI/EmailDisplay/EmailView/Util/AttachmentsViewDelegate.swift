//
//  AttachmentsViewDelegate.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 10.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

protocol AttachmentsViewDelegate: class {
    func didTap(attachment: Attachment, location: CGPoint, inView: UIView?)
}
