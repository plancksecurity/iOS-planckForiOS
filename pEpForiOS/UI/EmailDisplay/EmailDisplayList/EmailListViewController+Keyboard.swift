//
//  EmailListViewController+Keyboard.swift
//  pEp
//
//  Created by Martin Brude on 26/08/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

import pEpIOSToolbox

/// Protocol to handle keyboard hide/show events when having table view that occupes the full height.
protocol KeyboardHandlingProtocol {
    /// Constraint from Safe Area Bottom to Table View Bottom
    /// Set its priority to 1000
    var tableViewBottomConstraint : NSLayoutConstraint! { get }
    var tableView: UITableView!  { get set }
}

extension EmailListViewController : KeyboardHandlingProtocol {

    // MARK: Keyboard Handling

    /// Do not call this method directly.
    /// This will be called every time the keyboard will hide.
    /// - Parameter notification: The notification that informed the event.
    @objc func keyboardWillHide(notification: NSNotification) {
        tableViewBottomConstraint.constant = 0
    }

    /// Do not call this method directly.
    ///This will be called every time the keyboard will show.
    /// - Parameter notification: The notification that informed the event.
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize =
            (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue else {
                return
        }
        let toolbarHeight = navigationController?.toolbar.frame.size.height ?? 0
        tableViewBottomConstraint.constant = keyboardSize.height - toolbarHeight
        guard let animationDuration = keyBoardAnimationDuration(notification: notification) else {
            Log.shared.error("Fail to get keyboard animation duration")
            tableView.layoutIfNeeded()
            return
        }
        UIView.animate(withDuration: animationDuration,
                       delay: 0,
                       options: [],
                       animations: { [weak self] in
                        guard let me = self else {
                            // Valid, the view might be dismissed already.
                            return
                        }
                        me.view.superview?.layoutIfNeeded()
        })
    }

    // MARK: Notifications

    /// Subscribe for keyboard events.
    public func subscribeForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    /// Unsubscribe from all events.
    public func unsubscribeAll() {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Private

    private func keyBoardAnimationDuration(notification: NSNotification) -> Double? {
        guard let duration =
            notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                return nil
        }
        return duration
    }
}
