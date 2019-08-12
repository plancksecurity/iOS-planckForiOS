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

    func showHandshake(me: PEPIdentity,
                       partner: PEPIdentity,
                       completion: ((PEPSyncHandshakeResult)->())? = nil) {

        //Temp, working simple alert version
        DispatchQueue.main.async { [weak self] in
            guard let safeSelf = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }

            guard let meFPR = me.fingerPrint, let partnerFPR = partner.fingerPrint else {
                Log.shared.errorAndCrash("Missing FPRs")
                return
            }

            let lang = Locale.current.languageCode
            let trustwords = try! PEPSession().getTrustwordsFpr1(meFPR,
                                                                 fpr2: partnerFPR,
                                                                 language: lang,
                                                                 full: true)

            // Show Handshake
            let newAlertView = UIAlertController.pEpAlertController(title: "Handshake",
                                                                    message: trustwords,
                                                                    preferredStyle: .alert)
            // Accept Action
            newAlertView.addAction(UIAlertAction(title: "Confirm Trustwords", style: .default) { action in
                completion?(PEPSyncHandshakeResult.accepted)
            })

            // Reject Action
            newAlertView.addAction(UIAlertAction(title: "Wrong Trustwords", style: .destructive) { action in
                completion?(PEPSyncHandshakeResult.rejected)
            })

            // Cancel Action
            newAlertView.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
                completion?(PEPSyncHandshakeResult.cancel)
            })
            safeSelf.alertView = newAlertView

            guard let vc = safeSelf.presenter else {
                Log.shared.errorAndCrash("No Presenter")
                return
            }
            vc.present(newAlertView, animated: true, completion: nil)
        }

        //        DispatchQueue.main.async { [weak self] in
        //            let session = Session()
        //            session.performAndWait {
        //                let meIdentity = Identity.newObject(onSession: session)
        //                meIdentity.fingerprint = me.fingerPrint
        //
        //                let partnerIdentity = Identity.newObject(onSession: session)
        //                partnerIdentity.fingerprint = partner.fingerPrint
        //            }
        //        }
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

    func showSuccessfullyGrouped() {
        guard let vc = presenter else {
            Log.shared.errorAndCrash("No presenter")
            return
        }
        let title = NSLocalizedString("In Device Group",
                                      comment: "Title of alert in keysync protocol informing the user about successfull device grouping.")
        let message = NSLocalizedString("Your device has been added to the device group.", comment: "Message of alert in keysync protocol informing the user about successfull device grouping.")
        UIUtils.showAlertWithOnlyPositiveButton(title: title,
                                                message: message,
                                                inViewController: vc)
    }
}
