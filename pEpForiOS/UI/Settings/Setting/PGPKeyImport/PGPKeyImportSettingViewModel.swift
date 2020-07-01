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
        case passphrase
    }

    public struct Row {
        public let type: RowType
        public let title: String
        // If nil, do not set
        public let titleFontColor: UIColor?

        init(type: RowType, title: String, titleFontColor: UIColor? = nil) {
            self.type = type
            self.title = title
            self.titleFontColor = titleFontColor
        }
    }

    public struct Section {
        public let rows: [Row]
        public let title: NSAttributedString
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
            switch indexpath.row {
            case 0:
                delegate?.showSetPgpKeyImportScene()
            case 1:
                break
            default:
                Log.shared.error("Selected row not supported")
            }
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
        let pgpKeyImportTitleString = NSLocalizedString("To import an existing PGP private key, you first need to transfer it from your computer.\n\nClick here for more information. Once the private key has been transferred to the device, you can import it here.",
                                                        comment: "PGPKeyImportSetting row title")
        let pgpKeyImportSectionHeaderTitle = NSMutableAttributedString(string: pgpKeyImportTitleString,
                                                          attributes: nil)
        // // Setup link
        let linkString = NSLocalizedString("here",
                                           comment: "PGPKeyImportSettingViewModel - part of pgpKeyImportTitle that should link to support page (... click _here_ for info ...)")
        let linkRange = pgpKeyImportSectionHeaderTitle.mutableString.range(of: linkString)
        pgpKeyImportSectionHeaderTitle.addAttribute(NSAttributedString.Key.link,
                                       value: "https://pep.security/docs/ios.html#pgp-key-import",
                                       range: linkRange)
        pgpKeyImportSectionHeaderTitle.addAttribute(NSAttributedString.Key.foregroundColor,
                                       value: UIColor.pEpGreen,
                                       range: linkRange)
        let pgpKeyImportRowTitle = NSLocalizedString("PGP Key Import",
                                                     comment: "PGPKeyImportSetting pgpKeyImportRowTitle")
        let pgpKeyImportRow = Row(type: .pgpKeyImport,
                                  title: pgpKeyImportRowTitle,
                                  titleFontColor: .pEpGreen)

        // Passphrase
        let usePassphraseForNewKeys = NSLocalizedString("Use a Passphrase for new keys",
                                                     comment: "PGPKeyImportSetting - Use a Passphrase for new keys")
        let passphraseForNewKey = Row(type: .passphrase,
                                      title: usePassphraseForNewKeys,
                                      titleFontColor: .black)
        let pgpkeyImportSection = Section(rows: [pgpKeyImportRow, passphraseForNewKey],
                                          title: pgpKeyImportSectionHeaderTitle)
        // setOwnKeySection
        let setOwnKeySectionHeaderTitle = NSLocalizedString("ADVANCED",
                                                  comment: "setOwnKeyRowTitle row title")
        let setOwnKeyRowTitle = NSLocalizedString("Set Own Key",
        comment: "PGPKeyImportSetting setOwnKeyRowTitle")
        let setOwnKeyRow = Row(type: .setOwnKey, title: setOwnKeyRowTitle)
        let setOwnKeySection = Section(rows: [setOwnKeyRow],
                                       title: NSMutableAttributedString(string: setOwnKeySectionHeaderTitle,
                                                                        attributes: nil))
        sections = [pgpkeyImportSection, setOwnKeySection]
    }
}
