//
//  ExtraKeysSettingViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 13.08.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol ExtraKeysSettingViewModelDelegate {
    func showFprInvalidAlert()
    func refreshView()
}

class ExtraKeysSettingViewModel {
    typealias Fingerprint = String
    private var extraKeys = [ExtraKey]()

    var delegate: ExtraKeysSettingViewModelDelegate?

    var numRows: Int {
        return extraKeys.count
    }

    init(delegate: ExtraKeysSettingViewModelDelegate? = nil) {
        self.delegate = delegate
        reset()
    }

    subscript(index: Int) -> Fingerprint {
        get {
            return extraKeys[index].fingerprint
        }
    }

    var isEditable: Bool {
        return AppSettings.extraKeysEditable
    }

    /// Updates or creates an ExtraKey.
    ///
    /// - Parameter fpr: fingerprint to of extraKey
    /// - Throws: an Error in case the FPR is invalid
    func handleAddButtonPress(fpr: Fingerprint) {
        do {
            try ExtraKeysService.store(fpr: fpr)
            reset()
            delegate?.refreshView()
        } catch {
            delegate?.showFprInvalidAlert()
        }
    }

    func handleDeleteActionTriggered(for row: Int) {
        let extraKey = extraKeys.remove(at: row)
        extraKey.delete()
        extraKey.session.commit()
        //BUFF: is SwipeKit removing the row?
    }


}

// MARK: - Private

extension ExtraKeysSettingViewModel {

    private func reset() {
        extraKeys = ExtraKeysService.extraKeys
    }
}
