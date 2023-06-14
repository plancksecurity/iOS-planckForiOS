//
//  AuditLoginViewModel.swift
//  planckForiOS
//
//  Created by Martin Brude on 6/6/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation
import PlanckToolbox

extension AuditLoginViewModel {

    public enum RowType {
        case maxSize
    }

    public struct Row {
        public let type: RowType
        public let title: String

        init(type: RowType, title: String) {
            self.type = type
            self.title = title
        }
    }

    public struct Section {
        public let rows: [Row]
    }
}

class AuditLoginViewModel {

    public var size: Double = 1

    public private(set) var sections = [Section]()

    /// Number of elements in items
    public var count: Int {
        get {
            return sections.count
        }
    }

    init() {
        if MDMUtil.isEnabled() {
            Log.shared.errorAndCrash("If MDM is enabled. The file max size must be configured through MDM")
        }
        setupSections()
    }
    
    public var placeholder: String {
        return String(AppSettings.shared.auditLogginSize)
    }

    // The size of the audit log can be adjusted,
    // a default value of 1MB can be defined through config/MDM settings
    public func saveAuditLogSize() {
        AppSettings.shared.auditLogginSize = size
    }
    
    public var currentAuditLogginSize : Double = 1

    public func shouldEnableSaveButton(newValue : Double) -> Bool {
        currentAuditLogginSize = newValue
        return newValue >= 1 && newValue <= 5
    }
    
    private func setupSections() {
        let title = NSLocalizedString("Audit Loggin file max size", comment: "AuditLogin Setting -  Audit Loggin file max size")
        let row = Row(type: .maxSize, title: title)
        let maxSizeRow = Section(rows: [row])
        sections = [maxSizeRow]
    }
}

