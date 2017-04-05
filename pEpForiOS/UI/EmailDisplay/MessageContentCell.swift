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

    var webView: WKWebView!
    
    open var messageBody: String?
    var oldContentHeight: CGFloat = 0

    var contentSizeConstraints = [NSLayoutConstraint]()

    open override func awakeFromNib() {
        super.awakeFromNib()

        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: CGRect.zero, configuration: webConfiguration)
        webView.scrollView.addObserver(self, forKeyPath: contentSizeKeyPath,
                                       options: [.new, .old], context: nil)

        contentView.addSubview(webView)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false

        setupConstraints()
    }

    deinit {
        webView.scrollView.removeObserver(self, forKeyPath: contentSizeKeyPath)
    }

    func setupConstraints() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        if let margins = contentView.superview?.layoutMarginsGuide {
            contentView.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 0)
            contentView.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 0)
            contentView.topAnchor.constraint(equalTo: margins.topAnchor, constant: 0)
            contentView.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: 0)
        }

        let margin: CGFloat = 8
        addConstraint(NSLayoutConstraint(
            item: webView, attribute: .top, relatedBy: .equal, toItem: contentView,
            attribute: .top, multiplier: 1.0, constant: margin))
        addConstraint(NSLayoutConstraint(
            item: webView, attribute: .left, relatedBy: .equal, toItem: contentView,
            attribute: .left, multiplier: 1.0, constant: margin))
        addConstraint(NSLayoutConstraint(
            item: webView, attribute: .right, relatedBy: .equal, toItem: contentView,
            attribute: .right, multiplier: 1.0, constant: -margin))
        addConstraint(NSLayoutConstraint(
            item: webView, attribute: .bottom, relatedBy: .equal, toItem: contentView,
            attribute: .bottom, multiplier: 1.0, constant: -margin))
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

    func updateWebViewSizeConstraints(contentSize: CGSize) {
        contentView.removeConstraints(contentSizeConstraints)
        contentSizeConstraints.removeAll()
        contentSizeConstraints.append(NSLayoutConstraint(
            item: webView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width,
            multiplier: 1.0, constant: contentSize.width))
        contentSizeConstraints.append(NSLayoutConstraint(
            item: webView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height,
            multiplier: 1.0, constant: contentSize.height))
        contentView.addConstraints(contentSizeConstraints)
        contentView.setNeedsLayout()

        for v in [contentView, webView] {
            if v.hasAmbiguousLayout {
                for axis in [UILayoutConstraintAxis.horizontal, .vertical] {
                    let cs = v.constraintsAffectingLayout(for: axis)
                    print("\(axis): \(cs)")
                }
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
                    updateWebViewSizeConstraints(contentSize: newValue)
                }
            }
        }
    }
}
