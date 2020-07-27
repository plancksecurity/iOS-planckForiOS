//
//  KeySyncHandshakeViewModel.swift
//  pEp
//
//  Created by Alejandro Gelos on 05/07/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import PEPObjCAdapterFramework  //!!!: IOS-2325_! (RM)
import MessageModel

protocol KeySyncHandshakeViewModelDelegate: class {
    func showPicker(withLanguages languages: [String], selectedLanguageIndex: Int?)
    func closePicker()
    func change(handshakeWordsTo: String)
}

final class KeySyncHandshakeViewModel {
    enum Action {
        case cancel, decline, accept, changeLanguage
    }

    private struct Localized {
        struct Message {
            static let twoDevices = NSLocalizedString("Please make sure you have both devices together so you can compare the Trustwords on both devices. Are the Trustwords below equal to the Trustwords on the other device?",
                                               comment: "keySync handshake alert message for two devices in group")
            static let moreThanTwoDevices = NSLocalizedString("Please make sure you have the devices together so you can compare the Trustwords on the devices. Are the Trustwords below equal to the Trustwords on the other device?",
                                                       comment: "keySync handshake alert message for more than two devices in group")
        }
    }

    var completionHandler: ((KeySyncHandshakeViewController.Action) -> Void)? //!!!: A viewModel must not know the Controller

    weak var delegate: KeySyncHandshakeViewModelDelegate?
    var fullTrustWords = false //Internal since testing
    private var languageCode = Locale.current.languageCode ?? "en"
    private var meFPR: String?
    private var partnerFPR: String?
    private var isNewGroup = true
    private let pEpSession: PEPSessionProtocol

    private var _languages = [PEPLanguage]()

    private var oldLanguages: [PEPLanguage] {  //!!!: IOS-2325_! ?
        guard _languages.isEmpty else {
            return _languages
        }
        do {
            _languages = try pEpSession.languageList()  //!!!: IOS-2325_! ?
            return _languages
        } catch {
            Log.shared.errorAndCrash("%@", error.localizedDescription)
            return []
        }
    }

    init(pEpSession: PEPSessionProtocol = PEPSession()) {
        self.pEpSession = pEpSession
    }

    func languages(completion: @escaping ([PEPLanguage]) -> ()) {
        if !_languages.isEmpty {
            completion(_languages)
        } else {
            PEPAsyncSession().languageList({ (error) in
                Log.shared.errorAndCrash("%@", error.localizedDescription)
                completion([])
            }) { (theLangs) in
                self._languages = theLangs // TODO: potential memory leak
                completion(theLangs)
            }
        }
    }

    func didSelect(languageRow: Int) {
        languageCode = oldLanguages[languageRow].code
        delegate?.closePicker()
        updateTrustwords()
    }

    func handle(action: Action) {
        switch action {
        case .accept, .cancel, .decline:
            guard let action = viewControllerAction(viewModelAction: action) else {
                return
            }
            completionHandler?(action)
        case .changeLanguage:
            handleChangeLanguageButton()
        }
    }

    func setFingerPrints(meFPR: String?,
                         partnerFPR: String?,
                         isNewGroup: Bool) {
        self.meFPR = meFPR
        self.partnerFPR = partnerFPR
        self.isNewGroup = isNewGroup
        updateTrustwords()
    }

    func didLongPressWords() { //!!!: IOS-2325_!
        fullTrustWords = !fullTrustWords
        updateTrustwords()
    }

    func getMessage() -> String {
        return isNewGroup
            ? Localized.Message.twoDevices
            : Localized.Message.moreThanTwoDevices
    }
}

// MARK: - Private

extension KeySyncHandshakeViewModel {

    private func updateTrustwords() {
        trustWords { [weak self] (trustWords) in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.delegate?.change(handshakeWordsTo: trustWords)
        }
    }

    private func trustWords(completion: @escaping (String)->Void) {
        guard let meFPR = meFPR, let partnerFPR = partnerFPR else {
            Log.shared.errorAndCrash("Nil meFingerPrints or Nil partnerFingerPrints")
            completion("")
            return
        }
        TrustManagementUtil().getTrustwords(forFpr1: meFPR, fpr2: partnerFPR, language: languageCode, full: fullTrustWords) { (trustwords) in
            DispatchQueue.main.async {
                completion(trustwords ?? "")
            }
        }
    }

    private func handleChangeLanguageButton() {
        guard !oldLanguages.isEmpty else {
            Log.shared.errorAndCrash("Wont show picker, no languages to show")
            return
        }
        let languagesNames = oldLanguages.map { $0.name }
        let selectedlanguageIndex = oldLanguages.map { $0.code }.firstIndex(of: languageCode)

        delegate?.showPicker(withLanguages: languagesNames,
                             selectedLanguageIndex: selectedlanguageIndex)
    }

    private func viewControllerAction(viewModelAction: KeySyncHandshakeViewModel.Action)
        -> KeySyncHandshakeViewController.Action? {
            switch viewModelAction {
            case .accept:
                return .accept
            case .cancel:
                return .cancel
            case .decline:
                return .decline
            case .changeLanguage:
                return nil
            }
    }
}
