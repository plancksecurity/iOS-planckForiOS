//
//  FolderThreading.swift
//  pEp
//
//  Created by Dirk Zimmermann on 04.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

class FolderThreading {
    static func factory() -> ThreadAwareFolderFactoryProtocol {
        return ThreadUnAwareFolderFactory()
    }
}
