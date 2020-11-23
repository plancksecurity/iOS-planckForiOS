//
//  Persistable.swift
//  MessageModel
//
//  Created by Andreas Buff on 28.06.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

public protocol Persistable {
    /// Deletes the object on the current session
    func delete()

    /// True if the the object you are calling this on has been deleted.
    var isDeleted: Bool { get }
}
