//
//  Model.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 02/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

public protocol IModel {
    func save()
}

public class Model: IModel {
    let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    public func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                Log.error(CoreDataUtil.comp, error: nserror)
                abort()
            }
        }
    }
}