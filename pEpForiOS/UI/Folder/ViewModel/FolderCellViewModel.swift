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

    var folder:Folder
    var level : Int

    public init(folder: Folder, level: Int) {
        self.folder = folder
        self.level = level
    }

    var name:String {
        var n = ""
        if let parent = self.folder.parent {
            n = self.folder.name.replacingOccurrences(of: parent.name, with: "")
        }
        var ret = ""
        for _ in 0...level {
            ret = ret + "   "
        }
        if n != "" {
            ret += n
        } else {
            ret += self.folder.name
        }
        return ret
    }

    /*var name:String {
        if let parent = self.folder.parent {
            if let range = self.folder.name.range(of: parent.name) {
                return self.folder.name.substring(from: range.upperBound)
                //return self.folder.name.replacingOccurrences(of: self.folder.parent?.name, with: "")
            }
        }
        retur                   n self.folder.name
    }*/

    var leftPadding: Int {
        return level
    }
    
}
