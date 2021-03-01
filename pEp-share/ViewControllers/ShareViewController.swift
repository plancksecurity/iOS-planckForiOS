//
//  ShareViewController.swift
//  pEp-share
//
//  Created by Adam Kowalski on 14/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

import PEPIOSToolboxForAppExtensions

final class ShareViewController: UIViewController {
    var vm = ShareViewModel()
    var composeViewController: ComposeViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupComposeVC()

        guard let context = extensionContext else {
            Log.shared.errorAndCrash(message: "Lost extension context!")
            return
        }

        vm.checkInputItems(extensionContext: context)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ComposeViewController {
        }
    }

    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}

// MARK: - Private Extension

extension ShareViewController {
    private func setupComposeVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let composeVC = storyboard.instantiateViewController(withIdentifier: ComposeViewController.storyboardId) as? ComposeViewController else {
            Log.shared.errorAndCrash("Cannot instantiate ComposeViewController")
            return
        }
        composeViewController = composeVC
    }

    private func presentComposeVC() {
        guard let composeVC = composeViewController else {
            Log.shared.errorAndCrash("Have not instantiated yet a ComposeViewController")
            return
        }
        present(composeVC, animated: true, completion: nil)
    }
}
