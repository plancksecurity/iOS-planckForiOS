//: Playground - noun: a place where people can play

import UIKit

extension UIImage {
    open static func generate(size: CGSize, block: (CGContext, CGSize) -> ()) -> UIImage? {
        var theImage: UIImage?
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        if let ctx = UIGraphicsGetCurrentContext() {
            block(ctx, size)
            theImage = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        return theImage
    }
}

func produceDisabledBackground() -> UIImage? {
    func image(context: CGContext, size: CGSize) {
        let fillColor = UIColor.black
        var red, green, blue, alpha: CGFloat
        (red, green, blue, alpha) = (0, 0, 0, 0)
        fillColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        alpha = 1.0
        context.setFillColor(red: red, green: green, blue: blue, alpha: alpha)
        context.setStrokeColor(red: red, green: green, blue: blue, alpha: alpha)
        context.fill(CGRect(origin: CGPoint(x: 0, y: 0), size: size))
    }

    return UIImage.generate(size: CGSize(width: 100, height: 100), block: image)
}

produceDisabledBackground()
