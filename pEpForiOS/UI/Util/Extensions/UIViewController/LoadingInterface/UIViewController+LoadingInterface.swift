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
        initLoadingInterfaceIfNeeded()

    }

    func removeLoadingInterface() {
        guard loadingInterface != nil else {
            return
        }
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            self?.loadingInterface?.alpha = 0
        }, completion: { [weak self] _ in
            
            self?.loadingInterface?.removeFromSuperview()
        })

    }

    private func initLoadingInterfaceIfNeeded() {
        guard loadingInterface == nil else {
            return
        }
        loadingInterface = loadingInterfaceFromXib()
    }

    private func loadingInterfaceFromXib() -> UIView? {
        let uiNib = UINib(nibName: Constants.XibNames.loadingInterface, bundle: .main)
        guard let loadingView = uiNib.instantiate(withOwner: nil, options: nil)[0] as? UIView else {
            return nil
        }
        return loadingView
    }
}
