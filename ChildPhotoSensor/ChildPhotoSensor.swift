//
//  ChildPhotoSensor.swift
//  ChildPhotoSensor
//
//  Created by Ari on 12/31/17.
//  Copyright © 2017 Logical Nonsense LLC. All rights reserved.
//

import UIKit
import Vision

class ChildPhotoSensor {
    private var image = UIImage()
    
    var faces = 0 //number of faces detected in the image
    
    var nudityProb: Double? //probibility that the image contains a nude picture
    var nudity:Bool? //boolean indicating if the image contains nudity
    
    var minor: Bool? //boolean indicating if the image contains a minor
    var minorProb: Double? //probibility that the image contains a minor
    
    var safe: Bool? //boolean indicating if the image is safe(does not contain child pornography)
    init(image: UIImage) {
        self.image = image
        self.detectFaces { (faces) in
            if(faces){
                self.checkNudity({ (done) in
                    if(done){
                        self.checkAge({ (done) in
                            if(done){
                                self.safe = !(self.minor! && self.nudity!)
                            }
                        })
                    }
                })
            }
        }
        print(self.faces)
    }
    private func detectFaces(_ completion: @escaping (Bool) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(false)
            fatalError("Invalid image")
        }
        let request = VNDetectFaceRectanglesRequest { [unowned self] request, err in
            guard err == nil else {
                print(err!)
                completion(false)
                return
            }
            guard let detectedFaces = request.results else {
                return
            }
            self.faces = detectedFaces.count
            if(self.faces  > 0){
                completion(true)
            }
        }
        request.preferBackgroundProcessing = true
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
    private func checkNudity(_ completion: @escaping (Bool) -> Void){
        let model = Nudity()
        let size = CGSize(width: 224, height: 224)
        self.buffer(size: size) { (buffer) in
            guard let result = try? model.prediction(data: buffer) else {
                completion(false)
                fatalError("Prediction failed!")
            }
            self.nudityProb = result.prob["NSFW"]! * 100.0
            if(nudityProb! > 80.0){
                nudity = true
                completion(true)
            }
            else{
                nudity = false
                completion(true)
            }
        }
    }
    private func checkAge(_ completion: @escaping (Bool) -> Void){
        let model = AgeNet()
        let size = CGSize(width: 227, height: 227)
        self.buffer(size: size) { (buffer) in
            guard let result = try? model.prediction(data: buffer) else {
                completion(false)
                fatalError("Prediction failed!")
            }
            print(result.classLabel)
            print(result.prob)
            minorProb = (result.prob["0-2"]! + result.prob["4-6"]! + result.prob["8-12"]! + result.prob["15-20"]! ) * 100.0
            if(minorProb! > 30.0){
                minor = true
                completion(true)
            }
            else{
                minor = false
                completion(true)
            }
        }
    }
    private func buffer(size: CGSize, _ completion: (CVPixelBuffer) -> Void) {
        guard let buffer = image.resize(to: size)?.pixelBuffer() else {
            fatalError("Scaling or converting to pixel buffer failed!")
        }
        completion(buffer)
    }
}
extension UIImage {
    func resize(to newSize: CGSize) -> UIImage? {
        guard self.size != newSize else { return self }
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        defer { UIGraphicsEndImageContext() }
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func pixelBuffer() -> CVPixelBuffer? {
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        
        let attributes = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attributes, &pixelBuffer)
        guard status == kCVReturnSuccess else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: CGFloat(height))
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}
