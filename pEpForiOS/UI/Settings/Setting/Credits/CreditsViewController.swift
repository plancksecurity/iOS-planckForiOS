//
//  CreditsViewController.swift
//  pEp
//
//  Created by Andreas Buff on 13.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import WebKit

import pEpIOSToolbox

class CreditsViewController: UIViewController {
    @IBOutlet public weak var verboseLoggingSwitch: UISwitch!

    private var viewModel = CreditsViewModel()
    private var secretTapGesture: UITapGestureRecognizer?

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        verboseLoggingSwitch.isOn = AppSettings.shared.verboseLogginEnabled
        installLogViewGesture()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let theSecretTapGesture = secretTapGesture {
            view.removeGestureRecognizer(theSecretTapGesture)
        }
    }

    @IBAction public func switchedVerboseLoggingEnabled(_ sender: UISwitch) {
        viewModel.handleVerboseLoggingSwitchChange(newValue: sender.isOn)
    }

    private func installLogViewGesture() {
        let theSecretTapGesture = UITapGestureRecognizer(target: self,
                                                         action: #selector(secretGestureAction(_:)))
        theSecretTapGesture.numberOfTouchesRequired = 3
        theSecretTapGesture.numberOfTapsRequired = 5
        secretTapGesture = theSecretTapGesture
        view.addGestureRecognizer(theSecretTapGesture)
    }
}

extension CreditsViewController: SegueHandlerType {
    /// Identifier of the segues.
    public enum SegueIdentifier: String {
        case segueShowLog
    }
}

extension CreditsViewController {
    private func copyEngineFiles() {
        // Handle errors when traversing/enumerating the dir
        func errorHandler(url: URL, error: Error) -> Bool {
            Log.shared.log(error: error)
            return true
        }

        let fm = FileManager.default

        let appSupportUrls = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let appSupportUrl = appSupportUrls.first else {
            Log.shared.logError(message: "Cannot get application support directory")
            return
        }

        let documentUrls = fm.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentUrl = documentUrls.first else {
            Log.shared.logError(message: "Cannot get documents directory")
            return
        }

        let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey])
        guard let directoryEnumerator = fm.enumerator(at: appSupportUrl,
                                                      includingPropertiesForKeys: Array(resourceKeys),
                                                      options: .skipsHiddenFiles,
                                                      errorHandler: errorHandler) else {
            Log.shared.logError(message: "Cannot enumerate application support directory")
            return
        }

        var fileURLs: [URL] = []
        for case let fileURL as URL in directoryEnumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                  let isDirectory = resourceValues.isDirectory,
                  let name = resourceValues.name
            else {
                Log.shared.logError(message: "Cannot get resourceValues of file \(fileURL)")
                continue
            }

            if isDirectory {
                if name == "_extras" {
                    directoryEnumerator.skipDescendants()
                }
            } else {
                fileURLs.append(fileURL)
            }
        }
    }

    @IBAction public func secretGestureAction(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            copyEngineFiles()
            performSegue(withIdentifier: SegueIdentifier.segueShowLog, sender: self)
        }
    }
}
