//: Playground - noun: a place where people can play

import UIKit

extension UIColor {
    convenience init(hex: String) {
        var hexstr = hex
        if hexstr.hasPrefix("#") {
            hexstr = String(hexstr.characters.dropFirst())
        }

        var rgbValue: UInt32 = 0
        Scanner(string: hexstr).scanHexInt32(&rgbValue)

        let r = CGFloat((rgbValue >> 16) & 0xff) / 255.0
        let g = CGFloat((rgbValue >> 08) & 0xff) / 255.0
        let b = CGFloat((rgbValue >> 00) & 0xff) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

extension UIImage {
    open static func generate(size: CGSize, block: (CGContext) -> ()) -> UIImage? {
        var theImage: UIImage?
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        if let ctx = UIGraphicsGetCurrentContext() {
            block(ctx)
            theImage = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        return theImage
    }
}

extension String {
    func prefix(ofLength: Int) -> String {
        if self.characters.count >= ofLength {
            let start = self.startIndex
            return self.substring(to: self.index(start, offsetBy: ofLength))
        } else {
            return self
        }
    }

    func initials() -> String {
        let words = self.characters.split(separator: " ").map(String.init).map() {
            return $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if words.count == 0 {
            return "?"
        }
        if words.count == 1 {
            return self.prefix(ofLength: 2)
        }
        let word1 = words[0]
        let word2 = words[words.count - 1]
        return word1.prefix(ofLength: 1) + word2.prefix(ofLength: 1)
    }

    /**
     Draws `text` in the context `ctx` in the given `color`, centered in a rectangle with
     size `size`.
     */
    func draw(ctx: CGContext, centeredIn size: CGSize, color: UIColor, font: UIFont) {
        let wholeRect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        let nsString = self as NSString
        let textAttributes: [String : Any] = [
            NSStrokeColorAttributeName: color,
            NSForegroundColorAttributeName: color,
            NSFontAttributeName: font]
        let stringSize = nsString.size(attributes: textAttributes)
        let textRect = center(size: stringSize, inRect: wholeRect)
        nsString.draw(in: textRect, withAttributes: textAttributes)
    }
}

/**
 - Returns: A font with a size that will make drawing `text` just barely fit into `size`.
 */
func maximize(text: String, inSize size: CGSize,
              font: UIFont = UIFont.preferredFont(forTextStyle: .title1)) -> UIFont {
    let nsString = text as NSString
    var fontSize: CGFloat = 12.0
    var lastFont = font

    while true {
        let currentFont = font.withSize(fontSize)
        let textAttributes: [String : Any] = [NSFontAttributeName: currentFont]
        let stringSize = nsString.size(attributes: textAttributes)
        if stringSize.width > size.width || stringSize.height > size.height {
            return lastFont
        }
        lastFont = currentFont
        fontSize += 0.5
    }
}

func drawCircle(ctx: CGContext, size: CGSize, color: UIColor) {
    let bgColor = color.cgColor
    ctx.setFillColor(bgColor)
    ctx.setStrokeColor(bgColor)
    let r = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
    ctx.fillEllipse(in: r)
}

/**
 - Returns: A rectangle of size `size` in the center of `inRect`.
 */
func center(size: CGSize, inRect: CGRect) -> CGRect {
    let xStart = inRect.size.width / 2 - size.width / 2
    let yStart = inRect.size.height / 2 - size.height / 2
    let o = CGPoint(x: xStart, y: yStart)
    return CGRect(origin: o, size: size)
}

func drawInitialText(name: String, size: CGSize, padding: CGSize, ctx: CGContext) {
    let textColor = UIColor.white
    let text = name.initials()

    var textSize = size
    textSize.width -= padding.width
    textSize.height -= padding.height

    let font = maximize(text: text, inSize: textSize)
    text.draw(ctx: ctx, centeredIn: size, color: textColor, font: font)
}

func identityImageFromName(name: String, size: CGSize = CGSize(width: 64, height: 64),
                           padding: CGSize = CGSize(width: 10, height: 10)) -> UIImage? {
    return UIImage.generate(size: size) { ctx in
        drawCircle(ctx: ctx, size: size, color: UIColor(hex: "#c8c7cc"))
        drawInitialText(name: name, size: size, padding: padding, ctx: ctx)
    }
}

identityImageFromName(name: "Bryant")

identityImageFromName(name: "Eldon Tyrell")

"Bryant".initials()
"Priscilla Stratton".initials()
"Eldon Tyrell".initials()
"David Holden".initials()
"J.F. Sebastian".initials()
"Johann Sebastian Bach".initials()
"".initials()
