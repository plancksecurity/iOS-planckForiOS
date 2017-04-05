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

open class MessageContentCell: MessageCell {
    let contentSizeKeyPath = "contentSize"

    let webContentInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

    var webView: WKWebView!
    
    open var messageBody: String?
    var oldContentHeight: CGFloat = 0

    open override func awakeFromNib() {
        super.awakeFromNib()

        let webConfiguration = WKWebViewConfiguration()
        let webFrame = rectMinusInsets(rect: contentView.bounds, insets: webContentInsets)
        webView = WKWebView(frame: webFrame,
                            configuration: webConfiguration)
        webView.scrollView.addObserver(self, forKeyPath: contentSizeKeyPath,
                                       options: [.new, .old], context: nil)

        contentView.addSubview(webView)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
    }

    deinit {
        webView.scrollView.removeObserver(self, forKeyPath: contentSizeKeyPath)
    }

    func rectMinusInsets(rect: CGRect, insets: UIEdgeInsets) -> CGRect {
        return CGRect(x: rect.origin.x + insets.left, y: rect.origin.y + insets.top,
                      width: rect.size.width - insets.left - insets.right,
                      height: rect.size.height - insets.top - insets.bottom)
    }

    open override func layoutSubviews() {
        let contentHeight = webView.scrollView.contentSize.height
        let totalCellHeight = contentHeight + webContentInsets.top + webContentInsets.bottom

        webView.frame.size.height = contentHeight

        height = totalCellHeight
        if height != oldContentHeight {
            (delegate as? MessageContentCellDelegate)?.didUpdate(cell: self, height: height)
        }
        oldContentHeight = height
    }
    
    public override func updateCell(model: ComposeFieldModel, message: Message,
                                    indexPath: IndexPath) {
        super.updateCell(model: model, message: message, indexPath: indexPath)
        messageBody = message.longMessage
        webView.frame.origin = CGPoint.zero
        webView.frame.size = frame.size
        loadWebViewContent()
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

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                    change: [NSKeyValueChangeKey : Any]?,
                                    context: UnsafeMutableRawPointer?) {
        if keyPath == contentSizeKeyPath,
            let view = object as? UIScrollView,
            view == webView.scrollView {
            if let newValue = change?[NSKeyValueChangeKey.newKey] as? CGSize,
                let oldValue = change?[NSKeyValueChangeKey.oldKey] as? CGSize {
                if !oldValue.equalTo(newValue) {
                    setNeedsLayout()
                }
            }
        }
    }
}
