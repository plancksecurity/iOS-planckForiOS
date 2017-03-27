//
//  Date+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

extension Date {
    func isToday() -> Bool {
        let cal = Calendar.current
        return cal.isDateInToday(self)
    }

    func isRecent() -> Bool {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.day], from: self, to: now)
        if let days = comps.day {
            return days <= 7
        }
        return false
    }

    func smartString() -> String {
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
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    func fullString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
