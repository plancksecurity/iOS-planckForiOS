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
    let cell: HandshakePartnerTableViewCell
    let indexPath: IndexPath
    let viewModel: HandshakePartnerTableViewCellViewModel

    init(cell: HandshakePartnerTableViewCell,
         indexPath: IndexPath,
         viewModel: HandshakePartnerTableViewCellViewModel) {
        self.cell = cell
        self.indexPath = indexPath
        self.viewModel = viewModel
    }
}
