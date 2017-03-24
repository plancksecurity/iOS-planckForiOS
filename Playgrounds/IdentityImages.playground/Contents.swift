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
        let words = self.components(separatedBy: " ").map() {
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
}

func drawCircle(ctx: CGContext, size: CGSize, color: UIColor) {
    let bgColor = color.cgColor
    ctx.setFillColor(bgColor)
    ctx.setStrokeColor(bgColor)
    let r = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
    ctx.fillEllipse(in: r)
}

func identityImageFromName(name: String, size: CGSize = CGSize(width: 64, height: 64)) -> UIImage? {
    return UIImage.generate(size: size) { ctx in
        drawCircle(ctx: ctx, size: size, color: UIColor(hex: "#c8c7cc"))
    }
}

identityImageFromName(name: "Bryant")

"Bryant".initials()
"Priscilla Stratton".initials()
"Eldon Tyrell".initials()
"David Holden".initials()
"J.F. Sebastian".initials()
"".initials()
