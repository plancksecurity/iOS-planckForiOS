//
//  DebugTableView.swift
//  pEp
//
//  Created by Dirk Zimmermann on 01.03.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

/**
 Meant for debugging layout problems involving table views.
 */
class DebugTableView: UITableView {
    var keyboardObserver: Any?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addObservers()
    }

    deinit {
        removeObservers()
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            removeObservers()
        } else {
            addObservers()
        }
    }

    func addObservers() {
        if keyboardObserver == nil {
            keyboardObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name.UIKeyboardDidShow, object: nil,
                queue: OperationQueue.main) { [weak self] notification in
                    self?.keyboardDidShow(notification: notification)
            }
        }
    }

    func removeObservers() {
        if let kObs = keyboardObserver {
            NotificationCenter.default.removeObserver(kObs)
            keyboardObserver = nil
        }
    }

    func keyboardDidShow(notification: Notification) {
        print("\(#function)")
    }

    override var contentOffset: CGPoint {
        didSet {
            print("contentOffset: \(contentOffset)")
        }
    }

    override func scrollToRow(at indexPath: IndexPath, at scrollPosition: UITableViewScrollPosition,
                              animated: Bool) {
        super.scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
    }
}
