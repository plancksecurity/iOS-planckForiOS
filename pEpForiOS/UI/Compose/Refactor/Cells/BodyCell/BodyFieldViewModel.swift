//
//  BodyFieldViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

class BodyFieldViewModel: CellViewModel {
    let minHeigth: CGFloat = 240.0
    public var content: NSMutableAttributedString = NSMutableAttributedString(string: "")
    //IOS-1369: attachments go here?
}
