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

    private var alertView: UIAlertController? = nil
}

extension KeySyncHandshakeService: KeySyncServiceHandshakeDelegate {

    func showHandshake(me: PEPIdentity, partner: PEPIdentity) {

        //BUFF: debug without UI
//        DispatchQueue.main.async { [weak self] in
//            try! PEPSession().deliver(PEPSyncHandshakeResult.accepted, identitiesSharing: [me, partner])
//
//
//            return
//        }
            //FFUB

        //BUFF: HERE: add completionhandler
        DispatchQueue.main.async { [weak self] in
            guard let safeSelf = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            
            guard let meFPR = me.fingerPrint, let partnerFPR = partner.fingerPrint else {
                Log.shared.errorAndCrash("Missing FPRs")
                try? PEPSession().deliver(PEPSyncHandshakeResult.cancel,
                                          identitiesSharing: [me, partner])
                return
            }
            
            let trustwords = try! PEPSession().getTrustwordsFpr1(meFPR,
                                                                 fpr2: partnerFPR,
                                                                 language: nil,
                                                                 full: true)
            
            // Show Handshake
            let newAlertView = UIAlertController.pEpAlertController(title: "Handshake",
                                                                    message: trustwords,
                                                                    preferredStyle: .alert)
            newAlertView.addAction(UIAlertAction(title: "Confirm Trustwords", style: .default) { action in
                do {
                    try PEPSession().deliver(PEPSyncHandshakeResult.accepted,
                                             identitiesSharing: [me, partner])
                } catch {
                    return
                }
            })
            newAlertView.addAction(UIAlertAction(title: "Wrong Trustwords", style: .destructive) { action in
                do {
                    try PEPSession().deliver(PEPSyncHandshakeResult.rejected,
                                             identitiesSharing: [me, partner])
                } catch {
                    return
                }
            })
            newAlertView.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
                do {
                    try PEPSession().deliver(PEPSyncHandshakeResult.cancel,
                                             identitiesSharing: [me, partner])
                } catch {
                    return
                }
            })
            safeSelf.alertView = newAlertView
            
            guard let vc = safeSelf.presenter else {
                Log.shared.errorAndCrash("No Presenter")
                return
            }
            vc.present(newAlertView, animated: true, completion: nil)
            
        }
    }

    func cancelHandshake() {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.alertView?.dismiss(animated: true)
        }
    }
}
