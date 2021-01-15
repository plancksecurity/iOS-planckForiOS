//
//  UpdateIdentitiesAddressBookIdService.swift
//  MessageModel
//
//  Created by Andreas Buff on 15.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

/// Updates existing Identities with CNContact.identifier if found.
class UpdateIdentitiesAddressBookIdService: Service {
    let cnContactsAccessPermissionProvider: CNContactsAccessPermissionProviderProtocol

    required init(cnContactsAccessPermissionProvider: CNContactsAccessPermissionProviderProtocol) {
        self.cnContactsAccessPermissionProvider = cnContactsAccessPermissionProvider
        super.init()
        startBlock = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }

            guard cnContactsAccessPermissionProvider.userHasBeenAskedForContactAccessPermissions
                else {
                    // For better  user acceptance we want to ask the user for contact access
                    // permissions in the moment he uses a feature that requires access. Thus we
                    // do not touch CNContacts before that happened.
                    Log.shared.info("We do not have permissions to access CNContacts thus no Contacts will be imported.")
                    me.state = .ready
                return
            }
            me.startUpdate()
        }
        // Ignore finish. We do not repeat anyway.
        finishBlock = nil
        stopBlock = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.stopUpdate()
        }
    }

    private func startUpdate() {
        do {
            try startBackgroundTask { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                me.stopUpdate()
            }
        } catch {
            Log.shared.errorAndCrash(error: error)
        }

        DispatchQueue(label: #file + " startUpdate", qos: .background, attributes: []).async {
            [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            let moc = Stack.shared.newPrivateConcurrentContext
            AddressBook.updateExistingIdentities(context: moc)
            moc.perform {
                moc.saveAndLogErrors()
                me.state = .ready
                // We intentionally do not call `next()`. We are desinged to run once. The client
                // has to call `start()` again to make us run again.
                me.endBackgroundTask()
            }
        }
    }

    private func stopUpdate() {
        Log.shared.info("stopUpdate called")
        AddressBook.cancelUpdateExistingIdentities()
        state = .ready
        endBackgroundTask()
    }
}
