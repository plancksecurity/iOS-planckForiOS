//
//  Persistable.swift
//  MessageModel
//
//  Created by Andreas Buff on 28.06.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

public protocol Persistable { //!!!: think! obj.save() actually saves the main session. That is not very clear.
    /// Saves current Session
    func save()
    /// Deletes the object on the current session
    func delete()

    /// True if the the object you are calling this on has been deleted in the database.
    var isDeleted: Bool { get }
}
