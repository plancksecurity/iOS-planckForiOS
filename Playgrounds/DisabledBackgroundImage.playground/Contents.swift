//: Playground - noun: a place where people can play

import UIKit

extension UIColor {
    static let hexPEpGreen = "#4CD964"

    convenience init(hexString: String) {
        var hexstr = hexString
        if hexstr.hasPrefix("#") {
            hexstr = String(hexstr.dropFirst())
        }

        var rgbValue: UInt32 = 0
        Scanner(string: hexstr).scanHexInt32(&rgbValue)

        let r = CGFloat((rgbValue >> 16) & 0xff) / 255.0
        let g = CGFloat((rgbValue >> 08) & 0xff) / 255.0
        let b = CGFloat((rgbValue >> 00) & 0xff) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }

    open class var pEpGreen: UIColor {
        get {
            return UIColor(hexString: hexPEpGreen)
        }
    }
}

func getTargetDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
}

func getTargetFilePath(fileName: String) -> String {
    return getTargetDirectory().appendingPathComponent(fileName).path
}

func produceImage(size: CGSize, fileName: String, block: (CGContext, CGSize) -> ()) {
    let rect = CGRect(origin: CGPoint(), size: size)
    UIGraphicsBeginPDFContextToFile(fileName, rect, nil)
    UIGraphicsBeginPDFPage()
    if let ctx = UIGraphicsGetCurrentContext() {
        block(ctx, rect.size)
        UIGraphicsEndPDFContext()
    }
}

func disabledBackground() {
    func image(context: CGContext, size: CGSize) {
        let _ = UIColor.pEpGreen
    }

    produceImage(size: CGSize(width: 1, height: 1), fileName: "UITextFieldDisabledBackground",
                 block: image)
}
