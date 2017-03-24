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

func drawInitialText(name: String, size: CGSize, font: UIFont, ctx: CGContext) {
    let textColor = UIColor.white
    let text = name.initials()
    text.draw(ctx: ctx, centeredIn: size, color: textColor, font: font)
}

func identityImageFromName(name: String, size: CGSize = CGSize(width: 64, height: 64),
                           font: UIFont = UIFont.systemFont(ofSize: 24)) -> UIImage? {
    return UIImage.generate(size: size) { ctx in
        drawCircle(ctx: ctx, size: size, color: UIColor(hex: "#c8c7cc"))
        drawInitialText(name: name, size: size, font: font, ctx: ctx)
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
