//
//  LoggingViewController.swift
//  pEp
//
//  Created by Dirk Zimmermann on 07.10.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

class LoggingViewController: UIViewController {
    @IBOutlet weak var logTextView: UITextView!

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
    func scrollTextViewToBottom(textView: UITextView) {
        let theCount = textView.text.count
        if theCount > 0 {
            let location = theCount - 1
            let bottom = NSMakeRange(location, 1)
            textView.scrollRangeToVisible(bottom)
        }
    }

    func updateLogContents(logString: String) {
        logTextView.text = logString
        scrollTextViewToBottom(textView: logTextView)
    }
}
