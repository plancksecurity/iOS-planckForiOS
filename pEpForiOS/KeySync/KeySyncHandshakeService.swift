//
//  KeySyncHandshakeService.swift
//  pEp
//
//  Created by Andreas Buff on 07.06.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel
import PEPObjCAdapterFramework

class KeySyncHandshakeService {
    weak var presenter: UIViewController?

    // ALWAYS MUST close existing
//    func handleHandshakeRequest(_ object: UnsafeMutableRawPointer?,
//                                meFpr: String?,
//                                partnerFpr: String?,
//                                signal: PEPSyncHandshakeSignal) {
//        fatalError()
//        //TODO:
//        /*
//         PEPSyncHandshakeSignalUndefined = 0, // SYNC_NOTIFY_UNDEFINED = 0,
    //yet undefined
//
//         // request show handshake dialog
//         PEPSyncHandshakeSignalInitAddOurDevice = 1, // SYNC_NOTIFY_INIT_ADD_OUR_DEVICE = 1,
//         PEPSyncHandshakeSignalInitAddOtherDevice = 2, // SYNC_NOTIFY_INIT_ADD_OTHER_DEVICE = 2,
//         PEPSyncHandshakeSignalInitFormGroup = 3, // SYNC_NOTIFY_INIT_FORM_GROUP = 3,
//         // SYNC_NOTIFY_INIT_MOVE_OUR_DEVICE = 4,
//
//         // handshake process timed out
//         PEPSyncHandshakeSignalTimeout = 5, // SYNC_NOTIFY_TIMEOUT = 5,
//
//         // handshake accepted by user
//         PEPSyncHandshakeSignalAcceptedDeviceAdded = 6, // SYNC_NOTIFY_ACCEPTED_DEVICE_ADDED = 6,
//         PEPSyncHandshakeSignalAcceptedGroupCreated = 7, // SYNC_NOTIFY_ACCEPTED_GROUP_CREATED = 7,
//         // SYNC_NOTIFY_ACCEPTED_DEVICE_MOVED = 8,
    // allert: thumbs up
//
//         // handshake dialog must be closed
//         PEPSyncHandshakeSignalOvertaken = 9, // SYNC_NOTIFY_OVERTAKEN = 9,
//
//         // notificaton of actual group status
//         PEPSyncHandshakeSignalSole = 254, // SYNC_NOTIFY_SOLE = 254,
//         PEPSyncHandshakeSignalInGroup = 255 // SYNC_NOTIFY_IN_GROUP = 255
//         */
//
//
//        /*
//        PEPSession().deliver(<#T##result: PEPSyncHandshakeResult##PEPSyncHandshakeResult#>, identitiesSharing: <#T##[PEPIdentity]?#>)
//
//         PEPSyncHandshakeResultCancel = -1, // SYNC_HANDSHAKE_CANCEL = -1,
//         PEPSyncHandshakeResultAccepted = 0, // SYNC_HANDSHAKE_ACCEPTED = 0,
//         PEPSyncHandshakeResultRejected = 1 // SYNC_HANDSHAKE_REJECTED = 1
// */
//    }
}

extension KeySyncHandshakeService: KeySyncServiceHandshakeDelegate {
    func showHandshake(meFpr: String, partnerFpr: String) { //BUFF: HERE: add completionhandler
        DispatchQueue.main.async {

        guard let account = CdAccount.all()?.first as? CdAccount else {
            fatalError()
        }
        guard let testOwnID = cdAccount.identity else {
            fatalError()
        }
        
        let trustwords = try! PEPSession().getTrustwordsFpr1(meFpr, fpr2: partnerFpr, language: nil, full: true)
        print(trustwords)

        let me = PEPIdentity(address: testOwnID.address!,
                             userID: testOwnID.userID,
                             userName: testOwnID.userName,
                             isOwn: true)
        me.fingerPrint = meFpr
        let partner = PEPIdentity(address: testOwnID.address!,
                                  userID: testOwnID.userID,
                                  userName: testOwnID.userName,
                                  isOwn: true)
        partner.fingerPrint = partnerFpr

        do {
            try PEPSession().deliver(PEPSyncHandshakeResult.accepted,
                                  identitiesSharing: [me, partner])
        } catch {
            print(error)
        }
//        fatalError("unimplemented stub")

        // Show handshake.
        // report result
        }
    }

    func cancelHandshake() {
        DispatchQueue.main.async {

        fatalError("unimplemented stub")

        // dismiss possibly shown, KeySync related views
        }
    }
}
