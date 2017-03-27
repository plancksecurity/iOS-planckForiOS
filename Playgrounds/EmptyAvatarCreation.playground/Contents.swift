//: Playground - noun: a place where people can play

import UIKit

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

func drawCircle(ctx: CGContext, size: CGSize, color: UIColor) {
    let bgColor = color.cgColor
    ctx.setFillColor(bgColor)
    ctx.setStrokeColor(bgColor)
    let r = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
    ctx.fillEllipse(in: r)
}

let size = CGSize(width: 64, height: 64)
let circleColor = UIColor(hex: "#c8c7cc")

UIImage.generate(size: size) { ctx in
    drawCircle(ctx: ctx, size: size, color: circleColor)
}
