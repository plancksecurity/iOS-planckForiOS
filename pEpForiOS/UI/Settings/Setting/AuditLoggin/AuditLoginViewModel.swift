//
//  AuditLoggingViewModel.swift
//  planckForiOS
//
//  Created by Martin Brude on 6/6/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation
import PlanckToolbox

extension AuditLoggingViewModel {

    public enum RowType {
        case maxTime
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

class AuditLoggingViewModel {
    public var currentAuditLoggingTime : Int = 30

    public private(set) var sections = [Section]()

    /// Number of elements in items
    public var count: Int {
        get {
            return sections.count
        }
    }

    init() {
        if MDMUtil.isEnabled() {
            Log.shared.errorAndCrash("If MDM is enabled. The file max time must be configured through MDM")
        }
        setupSections()
    }

    public var placeholder: String {
        let format = NSLocalizedString("%1$@ days.", comment: "Days that the audit logging will register")
        let result = String.localizedStringWithFormat(format, String(AppSettings.shared.auditLoggingTime))
        return result
    }

    // The time frame of the audit log can be adjusted,
    // a default value of 30 days can be defined through config/MDM settings
    public func saveAuditLogTime() {
        AppSettings.shared.auditLoggingTime = currentAuditLoggingTime
    }

    public func shouldEnableSaveButton(newValue : Int) -> Bool {
        currentAuditLoggingTime = newValue
        return newValue >= 0
    }

    private func setupSections() {
        let title = NSLocalizedString("Audit Logging file max time", comment: "AuditLogging Setting -  Audit Logging file max time")
        let row = Row(type: .maxTime, title: title)
        let maxTimeRow = Section(rows: [row])
        sections = [maxTimeRow]
    }
}

