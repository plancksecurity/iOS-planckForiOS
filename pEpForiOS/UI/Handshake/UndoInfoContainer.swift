//
//  UndoInfoContainer.swift
//  pEp
//
//  Created by Dirk Zimmermann on 10.10.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Contains trust or mistrust undo information suitable for being used
/// in connection with an undo manager, being able to being cast to Any.
@objc class UndoInfoContainer: NSObject {
    let indexPath: IndexPath
    let viewModel: HandshakePartnerTableViewCellViewModel

    init(indexPath: IndexPath,
         viewModel: HandshakePartnerTableViewCellViewModel) {
        self.indexPath = indexPath
        self.viewModel = viewModel
    }
}
