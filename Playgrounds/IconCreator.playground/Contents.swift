//: Playground - noun: a place where people can play

import UIKit

func getTargetDirectory() -> URL {
    let paths = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
}

func getTargetFilePath(fileName: String) -> String {
    return getTargetDirectory().appendingPathComponent(fileName).path
}

func produceImage(fileName: String, block: (CGContext, CGSize) -> ()) {
    let rect = CGRect(origin: CGPoint(), size: CGSize(width: 60, height: 60))
    UIGraphicsBeginPDFContextToFile(fileName, rect, nil)
    UIGraphicsBeginPDFPage()
    if let ctx = UIGraphicsGetCurrentContext() {
        block(ctx, rect.size)
        UIGraphicsEndPDFContext()
    }
}

func produceRed() {
    let path = getTargetFilePath(fileName: "pep-user-status-red-stencil.pdf")
    produceImage(fileName: path) { ctx, size in
        let lineWidth: CGFloat = 2.0
        let inset: CGFloat = 4.0
        ctx.setStrokeColor(UIColor.red.cgColor)
        ctx.setLineWidth(lineWidth)
        let rect = CGRect(
            origin: CGPoint(x: lineWidth + inset, y: lineWidth + inset),
            size: CGSize(
                width: size.width - 2 * (lineWidth + inset), height: size.height - 2 * (lineWidth + inset)))
        ctx.stroke(rect, width: lineWidth)
    }
}

func produceYellow() {
    let path = getTargetFilePath(fileName: "pep-user-status-yellow-stencil.pdf")
    produceImage(fileName: path) { ctx, size in
        let lineWidth: CGFloat = 2.0
        ctx.setStrokeColor(UIColor.yellow.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.beginPath()
        let startP = CGPoint(x: size.width / 2, y: lineWidth)
        ctx.move(to: startP)
        ctx.addLine(to: CGPoint(x: lineWidth, y: size.height - lineWidth))
        ctx.addLine(to: CGPoint(x: size.width - lineWidth, y: size.height - lineWidth))
        ctx.addLine(to: startP)
        ctx.strokePath()
    }
}

func produceGreen() {
    let path = getTargetFilePath(fileName: "pep-user-status-green-stencil.pdf")
    produceImage(fileName: path) { ctx, size in
        // You would use UIBezierPath and its -addCurveToPoint:controlPoint1:controlPoint2: or -addQuadCurveToPoint:controlPoint: method. You'll have to calculate the control points yourself.
        let lineWidth: CGFloat = 2.0
        ctx.setStrokeColor(UIColor.green.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.beginPath()
        let startP = CGPoint(x: size.width / 2, y: lineWidth)
        let cpLeft = CGPoint(x: lineWidth, y: size.height/3)

        var cpRight = cpLeft
        cpRight.x = size.width - lineWidth
        ctx.move(to: startP)
        ctx.strokePath()
    }
}

produceRed()
produceYellow()
produceGreen()
