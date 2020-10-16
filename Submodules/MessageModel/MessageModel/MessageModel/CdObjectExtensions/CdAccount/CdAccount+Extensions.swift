//
//  CdAccount+Extensions.swift
//  MessageModel
//
//  Created by Andreas Buff on 14.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox

extension CdAccount {

    func server(type: Server.ServerType) -> CdServer? {
        guard let servs = servers?.allObjects as? [CdServer] else {
            return nil
        }
        let serversWithType = servs.filter { $0.serverType == type }

        if serversWithType.count == 0 {
            return nil
        }

        if serversWithType.count > 1 {
            let error = "Invalid state. CdAccount \(String(describing: identity?.address)) has more than one server of type \(type.asString()) assigned. Assigned servers: \(serversWithType)"
            Log.shared.errorAndCrash(message: error)
        }

        return serversWithType.first
    }

    func account() -> Account {
      return MessageModelObjectUtils.getAccount(fromCdAccount: self)
    }
}

// MARK: - Private

extension CdAccount {
    static func searchAccount(withAddress address: String, //BUFF: that is very wrongin multiple ways: 1) predicate factory not used. 2) bad naming 3) I am sure we already have a mthod to get CdAccount by address 4) is in section PRIVATE
                              context: NSManagedObjectContext) -> CdAccount? {
        let moc = context
        let p = CdAccount.PredicateFactory.by(address: address)
        let cdAcc = CdAccount.first(predicate: p, in: moc)

        return cdAcc
    }
}
