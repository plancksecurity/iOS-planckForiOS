//
//  Date+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

extension Date {
    public func isToday() -> Bool {
        let cal = Calendar.current
        return cal.isDateInToday(self)
    }

    public func isRecent() -> Bool {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.day], from: self, to: now)
        if let days = comps.day {
            return days < 7
        }
        return false
    }

    public func smartString() -> String {
        if isToday() {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter.string(from: self)
        }
        if isRecent() {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    public func shortString() -> String {
        let dateFormatter = DateFormatter.init()
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.timeStyle = DateFormatter.Style.short
        return dateFormatter.string(from: self)
    }

    public func fullString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
