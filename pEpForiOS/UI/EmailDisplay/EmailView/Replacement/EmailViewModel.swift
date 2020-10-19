//
//  EmailViewModel.swift
//  pEp
//
//  Created by Martín Brude on 19/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

//MB- Why do we need two methods to show a PDF?
protocol EmailViewModelDelegate: class {
    /// Show the preview of the Pdf in the provided URL
    /// - Parameter url: The url of the PDF
    func showPreview(ofPdfAt url : URL)
    /// Show Certificates Import View.
    func showClientCertificateImport()
    /// Present the PDF af the provided URL in a Document Controller
    /// - Parameter url: The url of the PDF
    func presentDocumentInteractionController(ofPdfAt url : URL)
}

struct EmailViewModel {
    
    struct Row {
        var type: ComposeFieldModel.FieldType
        var identifier: String
        var from: String
        var height: Double
    }
    
    public var shouldShowExternalContentView: Bool = false
    
    public var htmlViewerViewControllerExists: Bool = false
    
    private var rows : [Row]
    
    func htmlBody(from messageAtIndexPath: IndexPath) ->  String? {
        return nil
    }
    
    public subscript(index: Int) -> Row {
        get {
            return rows[index]
        }
    }
    
    public func appendInlinedPlainText(fromAttachmentsInMessageAt indexPath: IndexPath, to text: String) -> String {
        return ""
    }

    public func handleDidTapMessageAtIndexPath(indexPath: IndexPath) {
        
    }
//    didTap(cell: MessageCell, attachment: Attachment, location: CGPoint, inView: UIView?)
}
