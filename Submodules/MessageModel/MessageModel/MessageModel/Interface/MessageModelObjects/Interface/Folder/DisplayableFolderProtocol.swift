//
//  DisplayableFolder.swift
//  MessageModel
//
//  Created by Xavier Algarra on 02/04/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

///Protocol that app side will use to handle all the different uses of a folder object.
///this have to be implemented to be able to be displayed and used in ui side
public protocol DisplayableFolderProtocol {
    ///expected name to be displayed from this displayable folder
    var title: String { get }
    ///predicate to get the messages that belong to this displayable Folder
    var messagesPredicate: NSPredicate { get }
    ///Filter that will always display all the messages of this displayable Folder
    var defaultFilter: MessageQueryResultsFilter { get }
    ///Handles if a folder can be showed.
    var isSelectable: Bool { get }
    /// get the following 20 older messages of this folder.
    ///
    /// - Parameter completion: optional execution block that will be called once the fetch is compleeted
    func fetchOlder(completion: (()->())?)
    /// Fetches ALL mails newer than than the newest message in DB
    ///
    /// - Parameter completion: optional execution block that will be called once the fetch is compleeted
    func fetchNewMessages(completion: (()->())?)
}
