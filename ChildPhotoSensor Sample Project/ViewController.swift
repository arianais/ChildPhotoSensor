//
//  ViewController.swift
//  ChildPhotoSensor
//
//  Created by Ari on 12/31/17.
//  Copyright © 2017 Logical Nonsense LLC. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var safe: UILabel!
    @IBOutlet var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    private var faceRect = CGRect.zero
    
    private var image: UIImage? {
        didSet {
            DispatchQueue.main.async {
                self.imageView.image = self.image
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
    }
    
    func detectFaces(within uiImage: UIImage) {
        guard let cgImage = uiImage.cgImage else {
            fatalError("Invalid image")
        }
        
        let request = VNDetectFaceRectanglesRequest { [unowned self] request, err in
            guard err == nil else {
                print(err!)
                return
            }
            
            guard let results = request.results else {
                return
            }
            
            for case let result as VNFaceObservation in results {
                self.image = self.imageWith(size: uiImage.size, style: { ctx in
                    self.faceRect = self.rect(fromRelative: result.boundingBox, size: uiImage.size)
                    
                    ctx.setStrokeColor(UIColor.yellow.cgColor)
                    ctx.stroke(self.faceRect, width: 3.0)
                })!
            }
        }
        
        request.preferBackgroundProcessing = true
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    // MARK - IBActions
    
    @IBAction func tappedButton(_ sender: Any) {
        self.image = nil
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK - Private
    
    private func imageWith(size: CGSize, style: (CGContext) -> Void) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        self.image?.draw(at: .zero)
        style(ctx)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func rect(fromRelative boundingBox: CGRect, size: CGSize) -> CGRect {
        var rect = CGRect(
            x: boundingBox.origin.x * size.width,
            y: size.height - boundingBox.origin.y * size.height,
            width: boundingBox.width * size.width,
            height: boundingBox.height * size.height
        )
        
        rect.origin.y -= rect.height
        
        return rect
    }
    
    // MARK - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.image = pickedImage
            let photoSensor = ChildPhotoSensor(image: pickedImage)
            self.safe.text = "safe: \(photoSensor.safe!)"
        }
        dismiss(animated: true, completion: nil)
    }
    
}



