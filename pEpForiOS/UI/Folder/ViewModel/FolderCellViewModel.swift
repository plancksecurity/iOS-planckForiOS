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
    public var icon: UIImage {
        return self.folder.folderType.getIcon()
    }

    public var title : String {
        return self.name
    }

    public var number: Int {
        return 0 //fake number
    }

    public var arrow: UIImage {
        return UIImage(named: "arrow_down_icon")!
    }

    var folder: Folder
    var level : Int

    public init(folder: Folder, level: Int) {
        self.folder = folder
        self.level = level
    }

    private var name: String {
        return self.folder.localizedName
    }

    var leftPadding: Int {
        return level
    }
}
