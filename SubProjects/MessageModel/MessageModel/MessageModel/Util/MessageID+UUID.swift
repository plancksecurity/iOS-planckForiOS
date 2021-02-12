//
//  MessageID+UUID.swift
//  MailModel
//
//  Created by Dirk Zimmermann on 26/09/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

import UIKit

extension MessageID {
    static func generateUUID(localPart: String = "@pretty.Easy.privacy") -> String {
        return "\(UUID().uuidString)\(localPart)"
    }
}
