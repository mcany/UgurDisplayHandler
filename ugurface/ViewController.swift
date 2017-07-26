//
//  ViewController.swift
//  ugurface
//
//  Created by Ugur Kilic on 25/07/2017.
//  Copyright © 2017 urklc. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController {
    @IBOutlet weak var sourceImageView: UIImageView!
    @IBOutlet weak var resultImageView: UIImageView!

    var imageSelected = false
    var foundRects: [CGRect] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        sourceImageView.layer.borderWidth = 1.0
        sourceImageView.layer.borderColor = UIColor.darkGray.cgColor
        resultImageView.layer.borderWidth = 1.0
        resultImageView.layer.borderColor = UIColor.darkGray.cgColor
    }

    @IBAction func sourceImageTapped(_ sender: Any) {
        if !imageSelected {
            let picker = UIImagePickerController()
            picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
            picker.delegate = self
            present(picker, animated: true, completion: nil)

            foundRects = []
            imageSelected = true
            resultImageView.image = nil
        } else {
            if let recognizer = sender as? UITapGestureRecognizer {
                let point = recognizer.location(ofTouch: 0, in: recognizer.view!)
                let imagePercent = (point.x / sourceImageView.frame.size.width,
                                    point.y / sourceImageView.frame.size.height)

                let image = sourceImageView.image!
                let pointOnImage = CGPoint(x: image.size.width * imagePercent.0,
                                           y: image.size.height * imagePercent.1)
                if drawUgur(on: pointOnImage) {
                    imageSelected = !imageSelected
                }
            }
        }
    }

    @IBAction func shareImageTapped(_ sender: Any) {
        if let image = resultImageView.image {
            let controller = UIActivityViewController(activityItems: [image],
                                                      applicationActivities: nil)
            present(controller, animated: true, completion: nil)
        }
    }

    fileprivate func inspect(sourceImage: UIImage) {
        var resultImage = sourceImage
        let detectFaceRequest = VNDetectFaceLandmarksRequest { (request, error) in
            if let results = request.results as? [VNFaceObservation] {
                for faceObservation in results {
                    resultImage = self.drawDetectedRectangles(on: resultImage,
                                                              boundingRect: faceObservation.boundingBox)
                }
                self.sourceImageView.image = resultImage
            }
        }

        let vnImage = VNImageRequestHandler(cgImage: sourceImage.cgImage!, options: [:])
        try? vnImage.perform([detectFaceRequest])
    }
}

extension ViewController {
    fileprivate func drawDetectedRectangles(on sourceImage: UIImage,
                                            boundingRect: CGRect) -> UIImage {
        let context = prepareCGContext(image: sourceImage)

        // Draw detected face rectangle
        let width = sourceImage.size.width
        let height = sourceImage.size.height
        var actualRect = CGRect(x: boundingRect.origin.x * width,
                                y: boundingRect.origin.y * height,
                                width: boundingRect.size.width * width,
                                height: boundingRect.size.height * height)

        UIColor.red.setStroke()
        context.addRect(actualRect)
        context.drawPath(using: CGPathDrawingMode.stroke)

        // Update y since axis is translated
        actualRect.origin.y = (sourceImage.size.height) - (actualRect.origin.y + actualRect.size.height)
        foundRects.append(actualRect)

        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }

    fileprivate func drawUgur(on point: CGPoint) -> Bool {
        let selectedRect = foundRects.first { (rect) -> Bool in
            rect.contains(point)
        }
        guard var rect = selectedRect else {
            return false
        }

        if let ugurImage = UIImage(named: "ugur.png"),
            let resultImage = resultImageView.image {

            let context = prepareCGContext(image: resultImage)

            // Draw Ugur image on correct y position since coordinate space is scaled on y
            let margin: CGFloat = 10.0
            rect.size.width += margin
            rect.size.height += margin
            rect.origin.x -= margin / 2.0
            rect.origin.y = (resultImage.size.height - rect.origin.y) - rect.size.height + (margin / 2.0)

            context.draw(ugurImage.cgImage!, in: rect)

            let img = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            resultImageView.image = img
        }

        return true
    }

    private func prepareCGContext(image: UIImage) -> CGContext {
        UIGraphicsBeginImageContextWithOptions(image.size, false, 1)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: image.size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        context.draw(image.cgImage!, in: CGRect(x: 0.0, y: 0.0, width: image.size.width, height: image.size.height))

        return context
    }

    private func resizeImage(image: UIImage, fitRect: CGRect) -> UIImage {
        let widthRatio = fitRect.size.width / image.size.width
        let heightRatio = fitRect.size.height / image.size.height
        let scaleFactor = min(widthRatio, heightRatio)

        let newSize = CGSize(width: image.size.width * scaleFactor, height: image.size.height * scaleFactor)

        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(x: 0.0, y: 0.0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        let resizedImage = resizeImage(image: chosenImage, fitRect: sourceImageView.frame)
        inspect(sourceImage: resizedImage)
        resultImageView.image = resizedImage
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imageSelected = false
        dismiss(animated: true, completion: nil)
    }
}
