//
//  DocumentAttachmentPickerViewController.swift
//  pEp
//
//  Created by Andreas Buff on 24.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

#if !EXT_SHARE
import pEpIOSToolbox
#endif

class DocumentAttachmentPickerViewController: UIDocumentPickerViewController {
    var viewModel: DocumentAttachmentPickerViewModel?

    init(viewModel: DocumentAttachmentPickerViewModel? = nil) {
        self.viewModel = viewModel
        super.init(documentTypes: ["public.data"], in: .import)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
#if !EXT_SHARE
        let attributes =
        [ConstantEvents.Attributes.viewName : ConstantEvents.ViewNames.TutorialStep3View,
         ConstantEvents.Attributes.datetime : Date.getCurrentDatetimeAsString()
        ]
        EventTrackingUtil.shared.logEvent(ConstantEvents.ViewWasPresented, withEventProperties:attributes)
#endif
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
#if !EXT_SHARE
        let attributes =
        [ConstantEvents.Attributes.viewName : ConstantEvents.ViewNames.TutorialStep3View,
         ConstantEvents.Attributes.datetime : Date.getCurrentDatetimeAsString()
        ]
        EventTrackingUtil.shared.logEvent(ConstantEvents.ViewWasDismissed, withEventProperties:attributes)
#endif
    }
}

extension DocumentAttachmentPickerViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL]) {
        viewModel?.handleDidPickDocuments(at: urls)
    }
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        viewModel?.handleDidCancel()
    }
}
