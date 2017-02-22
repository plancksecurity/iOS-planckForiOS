//
//  FolderUiProtocols.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 21/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

public protocol SectionWithText {

    var title: String { get }

    var unreadMessages: String { get }

    var arrow : String { get }
    var collapsed: Bool { get set }

    func onCollapse(collapsed: Bool)
}

extension SectionWithText {
    //defaults
    var titleColor: UIColor {
        return UIColor.lightGray
    }

    var unreadMessagesColor: UIColor {
        return UIColor.darkGray
    }
}

public protocol CellWithIconTextNumberArrow {
    var icon: UIImage { get set }
    var title: String { get }
    var number: Int { get }
    var arrow: UIImage { get }

}

extension CellWithIconTextNumberArrow {
    //defaults
}
