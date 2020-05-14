//
//  PGPKeyImportViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 14.05.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

extension PGPKeyImportSettingViewModel {

    public struct Row {
        public let title: String
    }

    public struct Section {
        public let rows: [Row]
        public let title: String
    }
}

class PGPKeyImportSettingViewModel {
    public private(set) var sections = [Section]()

    public init() {
        setupSections()
    }

    public func handleDidSelect(rowAt indexpath: IndexPath) {
        fatalError("unimplemented stub")
        // show KeyImportVC
        // Show SetOwnKey
    }
}

// MARK: - Private

extension PGPKeyImportSettingViewModel {
    private func setupSections() {
        // pgpkeyImportSection
        let pgpKeyImportRow = Row(title: "PGP Key Import")
        let pgpkeyImportSection = Section(rows: [pgpKeyImportRow],
                                          title: "To import an existing PGP private key, you first need to transfer it from your computer. Click here for more information. Once the private key has been transferred to the device, you can import it here.")
        // setOwnKeySection
        let setOwnKeyRow = Row(title: "Set Own Key")
        let setOwnKeySection = Section(rows: [setOwnKeyRow],
                                       title: "ADVANCED")

        sections = [pgpkeyImportSection, setOwnKeySection]
    }
}
