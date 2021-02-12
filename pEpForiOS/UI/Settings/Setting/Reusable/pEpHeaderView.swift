//
//  PEPHeaderView.swift
//  pEp
//
//  Created by Adam Kowalski on 17/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit


extension PEPHeaderView {
    private struct Constants {
        struct Margin {
            static let top: CGFloat = 36
            static let bottom: CGFloat = 12
        }
    }
}

final class PEPHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "pEp Section Header"

    private let titleTextView: TextFieldWithoutSelection = {
        let createe = TextFieldWithoutSelection()
        createe.translatesAutoresizingMaskIntoConstraints = false
        createe.isScrollEnabled = false
        createe.isUserInteractionEnabled = false
        createe.isEditable = false
        return createe
    }()


    override var isUserInteractionEnabled: Bool {
        set {
            titleTextView.isUserInteractionEnabled = newValue
            super.isUserInteractionEnabled = newValue

        }
        get {
            return super.isUserInteractionEnabled
        }
    }

    public override var backgroundColor: UIColor? {
        set {
            super.backgroundColor = newValue
            setBackgroundColor(color: newValue)
        }
        get {
            return super.backgroundColor
        }
    }

    var title: String = "" {
        didSet {
            titleTextView.text = title
        }
    }

    var attributedTitle: NSAttributedString = NSAttributedString(string: "") {
        didSet {
            titleTextView.attributedText = attributedTitle
            setFont()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setUp()
    }
}

// MARK: - Private

extension PEPHeaderView {
    private func setUp() {
        backgroundColor = .groupTableViewBackground
        titleTextView.sizeToFit()
        contentView.addSubview(titleTextView)
        setFont()
        setConstraints()
    }

    private func setBackgroundColor(color: UIColor?) {
        super.backgroundColor = color
        contentView.backgroundColor = color
        titleTextView.backgroundColor = color
    }

    private func setFont() {
        let font = UIFont.pepFont(style: .subheadline, weight: .regular)

        titleTextView.textColor = .pEpGreyText
        titleTextView.font = font

        let mutableAttributedTitle = NSMutableAttributedString(attributedString: titleTextView.attributedText)
        mutableAttributedTitle.replaceFont(with: font)
        titleTextView.attributedText = mutableAttributedTitle
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            titleTextView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            titleTextView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            titleTextView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: Constants.Margin.top),
            titleTextView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -Constants.Margin.bottom).usingPriority(.defaultHigh)
        ])
    }
}

extension NSMutableAttributedString {
    /// Sets our font while keeping URL link attributes.
    /// Extend this method if you need to keep other attributes.
    fileprivate func replaceFont(with font: UIFont) {
        beginEditing()
        // Save existing link attributes to re-set later
        var existingLinkAttributes = [(URL, NSRange)]()
        enumerateAttribute(.link, in: wholeRange()) { (value, range, stop) in
            guard
                let urlString = value as? String,
                let url = URL(string: urlString)
                else {
                    return
            }
            existingLinkAttributes.append((url,range))
        }
        // Replace existing font attributes
        var didEdit = false
        enumerateAttribute(.font, in: wholeRange()) { (value, range, stop) in
            guard let f = value as? UIFont else {
                return
            }
            let ufd = f.fontDescriptor.withFamily(font.familyName).withSymbolicTraits(f.fontDescriptor.symbolicTraits)!
            let newFont = UIFont(descriptor: ufd, size: f.pointSize)
            removeAttribute(.font, range: range)
            addAttribute(.font, value: newFont, range: range)
            didEdit = true
        }
        if !didEdit {
            // No font was defined. Set font to complete text instead of replacing existing
            // font attributes.
            setAttributes([NSAttributedString.Key.font : font,
                           NSAttributedString.Key.foregroundColor: UIColor.pEpGreyText],
                          range: wholeRange())
        }
        // Re-set link attributes
        for linkAttribute in existingLinkAttributes {
            let linkUrl = linkAttribute.0
            let range = linkAttribute.1
            addAttributes([NSAttributedString.Key.link : linkUrl], range: range)
        }
        endEditing()
    }
}
