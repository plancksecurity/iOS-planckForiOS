//
//  PersistentSetup.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import XCTest
import CoreData

import MessageModel
import pEpForiOS

class PersistentSetup {
    /**
     Sets up persistence with an in-memory core data backend.
     */
    init() {
        loadCoreDataStack()
    }

    func loadCoreDataStack() {
        let objectModel = AppDataModel.appModel()

        do {
            try Record.loadCoreDataStack(
                managedObjectModel: objectModel, storeType: NSInMemoryStoreType)
        } catch {
            print("Error While Loading DataStack")
        }
    }
}
