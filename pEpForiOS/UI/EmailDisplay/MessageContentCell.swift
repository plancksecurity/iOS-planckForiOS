//
//  MessageContentCell.swift
//
//  Created by Yves Landert on 20.12.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import MessageModel

open class MessageContentCell: MessageCell, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    
    open var messageBody: String?
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
    }
    
    public override func updateCell(_ model: ComposeFieldModel, _ message: Message) {
        fieldModel = model
        messageBody = message.longMessage
        loadWebViewContent()
    }
    
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        height = webView.scrollView.contentSize.height
        (delegate as? MessageContentCellDelegate)?.didUpdate(cell: self, height: height)
    }
    
    fileprivate final func loadWebViewContent() {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let fontSize = font.pointSize
        let fontFamily = font.familyName
        
        if let url = URL(string: "file:///") {
            if let string = messageBody {
                let s2 = string.replacingOccurrences(of: "\r\n", with: "<br />")
                let s3 = s2.replacingOccurrences(of: "\n", with: "<br />")
                let html = "<!DOCTYPE html>"
                    + "<html>"
                    + "<head>"
                    + "<meta name=\"viewport\" content=\"initial-scale=1.0\" />"
                    + "<style>"
                    + "body {font-size: \(fontSize); font-family: '\(fontFamily)'; }"
                    + "</style>"
                    + "</head>"
                    + "<body>"
                    + s3
                    + "</body>"
                    + "</html>"
                
                webView.loadHTMLString(html, baseURL: url)
            }
        }
    }
}
