//
//  FolderViewModelDelegate.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 21/11/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol FolderViewModelDelegate: class {
    func folderViewModelDidUpdateFolderList(viewModel: FolderViewModel)
}
