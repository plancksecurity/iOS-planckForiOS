//: Playground - noun: a place where people can play

import UIKit

open class FlagImages {
    public static func create(imageSize: CGSize) -> FlagImages {
        let val = NSValue(cgSize: imageSize)
        if let o = sharedDict[val] {
            return o
        } else {
            let o = FlagImages(imageSize: imageSize)
            sharedDict[val] = o
            return o
        }
    }

    fileprivate static var sharedDict: [NSValue:FlagImages] = {
        let instance = [NSValue:FlagImages]()
        return instance
    }()

    let imageSize: CGSize

    public private(set) var flaggedImage: UIImage?
    public private(set) var notSeenImage: UIImage?
    public private(set) var flaggedAndNotSeenImage: UIImage?

    fileprivate init(imageSize: CGSize) {
        self.imageSize = imageSize
        createImages()
    }

    func createImages() {
        var circleSize = imageSize
        notSeenImage = createCircleImage(size: circleSize, color: .orange)
        flaggedImage = createCircleImage(size: circleSize, color: .blue)

        circleSize.width -= 5
        circleSize.height -= 5
        let flaggedImageSmall = createCircleImage(size: circleSize, color: .blue)

        flaggedAndNotSeenImage = createImageOverlay(
            size: imageSize, images: [notSeenImage, flaggedImageSmall])
    }

    func createImageOverlay(size: CGSize, images: [UIImage?]) -> UIImage? {
        return produceImage(size: size, block: { ctx in
            for img in images {
                if let theImg = img {
                    if let cg = theImg.cgImage {
                        var rect = CGRect(
                            x: 0.0, y: 0.0, width: theImg.size.width, height: theImg.size.height)
                        rect.origin.x = (size.width - theImg.size.width) / 2
                        rect.origin.y = (size.height - theImg.size.height) / 2
                        ctx.draw(cg, in: rect)
                    }
                }
            }
        })
    }

    func createCircleImage(size: CGSize, color: UIColor) -> UIImage? {
        return produceImage(size: size, block: { ctx in
            ctx.setFillColor(color.cgColor)
            ctx.setStrokeColor(color.cgColor)
            let r = CGRect.init(origin: CGPoint(x: 0.0, y: 0.0), size: size)
            ctx.fillEllipse(in: r)
        })
    }

    func produceImage(size: CGSize, block: (CGContext) -> ()) -> UIImage? {
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

func getTargetDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
}

func save(image: UIImage?, name: String) {
    if let img = image {
        if let data = UIImagePNGRepresentation(img) {
            let filename = getTargetDirectory().appendingPathComponent(name)
            print("filename \(filename)")
            try? data.write(to: filename)
        }
    }
}

let fi = FlagImages.create(imageSize: CGSize(width: 14, height: 14))

fi.flaggedImage
fi.flaggedAndNotSeenImage
fi.notSeenImage

save(image: fi.flaggedImage, name: "flagged.png")
save(image: fi.flaggedAndNotSeenImage, name: "flaggedAndNotSeenImage.png")
save(image: fi.notSeenImage, name: "notSeenImage.png")

