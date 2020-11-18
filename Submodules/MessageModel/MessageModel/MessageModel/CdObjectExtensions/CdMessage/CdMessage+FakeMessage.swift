//
//  CdMessage+FakeMessage.swift
//  MessageModel
//
//  Created by Andreas Buff on 21.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

extension CdMessage {
    
    var isFakeMessage: Bool {
        return uid == CdMessage.uidFakeResponsivenes
    }
}
