//
//  KeySyncHandshakeViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 05/07/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

final class KeySyncHandshakeViewController: UIViewController {
    
    @IBOutlet weak var titile: UILabel!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var keySyncWorlds: UITextView!

    private let viewModel = KeySyncHandshakeViewModel()

    func finderPrints(meFPR: String, partnerFPR: String) {
        viewModel.fingerPrints(meFPR: meFPR, partnerFPR: partnerFPR)
    }

    @IBAction func didPress(_ sender: UIButton) {
        guard let action = pressedAction(tag: sender.tag) else {
            return
        }
        viewModel.didPress(action: action)
    }
}

// MARK: - KeySyncHandshakeViewModelDelegate
extension KeySyncHandshakeViewController: KeySyncHandshakeViewModelDelegate {
    func didPress(action: KeySyncHandshakeViewModel.Action) {

    }

    func showPicker(withLanguages languages: [String]) {

    }

    func closePicker() {

    }

    func change(handshakeWordsTo: String) {
        DispatchQueue.main.async { [weak self] in
            self?.keySyncWorlds.text = handshakeWordsTo
        }
    }

}

// MARK: - Private
extension KeySyncHandshakeViewController {
    private func pressedAction(tag: Int) -> KeySyncHandshakeViewModel.Action? {
        switch tag {
        case 1:
            return .changeLanguage
        case 2:
            return .cancel
        case 3:
            return .decline
        case 4:
            return .accept
        default:
            return nil
        }
    }
}
