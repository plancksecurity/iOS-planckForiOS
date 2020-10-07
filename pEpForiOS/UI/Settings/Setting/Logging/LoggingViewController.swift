//
//  LoggingViewController.swift
//  pEp
//
//  Created by Dirk Zimmermann on 07.10.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

class LoggingViewController: UIViewController {
    private var viewModel = LoggingViewModel()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        viewModel.delegate = nil
    }
}

extension LoggingViewController: LogViewModelDelegate {
    func updateLogContents(logString: String) {
        print("**** have log!")
    }
}
