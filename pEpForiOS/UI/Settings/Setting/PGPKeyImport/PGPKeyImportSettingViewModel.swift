//
//  PGPKeyImportViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 14.05.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol PGPKeyImportSettingViewModelDelegate: class {
    func showSetPgpKeyImportScene()
    func showSetOwnKeyScene()
}

extension PGPKeyImportSettingViewModel {
    public enum RowType {
        case pgpKeyImport
        case setOwnKey
    }

    public struct Row {
        public let type: RowType
        public let title: String
    }

    public struct Section {
        public let rows: [Row]
        public let title: String
    }
}

class PGPKeyImportSettingViewModel {
    weak public var delegate: PGPKeyImportSettingViewModelDelegate?
    public private(set) var sections = [Section]()

    public init(delegate: PGPKeyImportSettingViewModelDelegate? = nil) {
        self.delegate = delegate
        setupSections()
    }

    public func handleDidSelect(rowAt indexpath: IndexPath) {
        switch indexpath.section {
        case 0: // Import PGP Key from Documents directory
            delegate?.showSetPgpKeyImportScene()
        case 1: // SetOwnKey
            delegate?.showSetOwnKeyScene()
        default:
            Log.shared.errorAndCrash("Unhandled case")
        }
    }
}

// MARK: - Private

extension PGPKeyImportSettingViewModel {
    private func setupSections() {
        // pgpkeyImportSection
        let pgpKeyImportTitle = NSLocalizedString("To import an existing PGP private key, you first need to transfer it from your computer. Click here for more information. Once the private key has been transferred to the device, you can import it here.",
                                                  comment: "PGPKeyImportSetting row title")
        let pgpKeyImportRow = Row(type: .pgpKeyImport, title: "PGP Key Import")
        let pgpkeyImportSection = Section(rows: [pgpKeyImportRow],
                                          title: pgpKeyImportTitle)
        // setOwnKeySection
        let setOwnKeyRowTitle = NSLocalizedString("ADVANCED",
                                                  comment: "setOwnKeyRowTitle row title")
        let setOwnKeyRow = Row(type: .setOwnKey, title: "Set Own Key")
        let setOwnKeySection = Section(rows: [setOwnKeyRow],
                                       title: setOwnKeyRowTitle)

        sections = [pgpkeyImportSection, setOwnKeySection]
    }
}
