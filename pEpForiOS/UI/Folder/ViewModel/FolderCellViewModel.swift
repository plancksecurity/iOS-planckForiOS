//
//  FolderViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 20/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class FolderCellViewModel {
    let folder: Folder
    let level : Int

    public var icon: UIImage {
        return self.folder.folderType.getIcon()
    }

    public var title : String {
        return self.name
    }

    private var name: String {
        return self.folder.localizedName
    }

    var leftPadding: Int {
        return level
    }

    public init(folder: Folder, level: Int) {
        self.folder = folder
        self.level = level
    }
}
