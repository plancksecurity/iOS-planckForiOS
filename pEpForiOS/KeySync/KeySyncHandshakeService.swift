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

            guard let viewController = safeSelf.presenter else {
                Log.shared.errorAndCrash("No Presenter")
                return
            }

            viewController.presentKeySyncWizard(meFPR: meFPR, partnerFPR: partnerFPR) { action in
                switch action {
                case .accept:
                    completion?(PEPSyncHandshakeResult.accepted)
                case .cancel:
                    completion?(PEPSyncHandshakeResult.cancel)
                case .decline:
                    completion?(PEPSyncHandshakeResult.rejected)
                case .leave:
                    break
                }
            }
        }
    }

    //!!!: unimplemented stub
    func showCurrentlyGroupingDevices() {
        // When implementing IOS-1712, show the additional (animated) view here.
        Log.shared.warn("Unimplemented stub. \n\n################################\n################################\nshowCurrentlyGroupingDevices called")
    }

    func cancelHandshake() {
        guard let keySyncHandShakeAlert  =
            presenter?.presentedViewController as? KeySyncHandshakeViewController else {
                return
        }
        DispatchQueue.main.async {
            keySyncHandShakeAlert.dismiss(animated: true)
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
