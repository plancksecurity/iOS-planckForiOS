//
//  UIViewController+LoadingInterface.swift
//  pEp
//
//  Created by Alejandro Gelos on 09/10/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

extension BaseViewController {
    func showLoadingInterface() {
        if loadingInterface == nil {
            addLoadingInterfaceToKeyWindow()
        }

        UIView.animate(withDuration: 0.3) {[weak self] in
            self?.loadingInterface?.alpha = 1
        }
    }

    func removeLoadingInterface() {
        guard loadingInterface != nil else { return }
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            self?.loadingInterface?.alpha = 0
        }, completion: { [weak self] finish in
            guard finish else { return }
            self?.loadingInterface?.removeFromSuperview()
        })
    }

    private func addLoadingInterfaceToKeyWindow() {
        guard let loadingInterface = loadingInterfaceFromXib(),
            let keyWindow = UIApplication.shared.keyWindow else {
                return
        }

        loadingInterface.alpha = 0
        loadingInterface.translatesAutoresizingMaskIntoConstraints = false

        self.loadingInterface = loadingInterface
        keyWindow.addSubview(loadingInterface)

        NSLayoutConstraint(item: loadingInterface, attribute: .leading, relatedBy: .equal, toItem: keyWindow, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: loadingInterface, attribute: .trailing, relatedBy: .equal, toItem: keyWindow, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: loadingInterface, attribute: .top, relatedBy: .equal, toItem: keyWindow, attribute: .top, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: loadingInterface, attribute: .bottom, relatedBy: .equal, toItem: keyWindow, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
    }

    private func loadingInterfaceFromXib() -> UIView? {
        let uiNib = UINib(nibName: Constants.XibNames.loadingInterface, bundle: .main)
        guard let loadingView = uiNib.instantiate(withOwner: nil, options: nil)[0] as? UIView else {
            Log.shared.errorAndCrash("Fail to init Loading Interface from xib")
            return nil
        }
        return loadingView
    }
}
