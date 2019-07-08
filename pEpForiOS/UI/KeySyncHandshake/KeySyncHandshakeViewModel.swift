//
//  KeySyncHandshakeViewModel.swift
//  pEp
//
//  Created by Alejandro Gelos on 05/07/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol KeySyncHandshakeViewModelDelegate: class {
    func didPress(action: KeySyncHandshakeViewModel.Action)
    func showPicker(withLanguages languages: [String])
    func closePicker()
    func change(handshakeWordsTo: String)
}

final class KeySyncHandshakeViewModel {
    enum Action {
        case cancel, decline, accept
    }

    weak var delegate: KeySyncHandshakeViewModelDelegate?

    func didPressLanguageButton() {

    }

    func didSelect(language: String?) {

    }

    func didPress(action: Action) {

    }
}
