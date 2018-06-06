//
//  ViewController.swift
//  MFCoreMLDemo
//
//  Created by 孟丰 on 2018/5/11.
//  Copyright © 2018年 MENGFENG. All rights reserved.
//

import UIKit
import CoreML
class ViewController: UIViewController,UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var resultLabel: UILabel!
    var model: Resnet50!
    var iamgeW: CGFloat = 0
    override func viewWillAppear(_ animated: Bool) {
//        model = Inceptionv3()
//        iamgeW = 299
        model = Resnet50()
        iamgeW = 224
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    @IBAction func cameraClick(_ sender: UIBarButtonItem) {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return;
        }
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self
        cameraPicker.sourceType = .camera
        cameraPicker.allowsEditing = false
        present(cameraPicker, animated: true, completion: nil)
        
    }
    
    @IBAction func libraryClick(_ sender: UIBarButtonItem) {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
extension ViewController: UIImagePickerControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        resultLabel.text = "分析图片..."
        
        guard let image = info["UIImagePickerControllerOriginalImage"] as? UIImage else {
            return
        }
        imageView.image = image
        UIGraphicsBeginImageContextWithOptions(CGSize(width: iamgeW, height: iamgeW), true, UIScreen.main.scale)
        image.draw(in: CGRect(x: 0, y: 0, width: iamgeW, height: iamgeW))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let attrs = [kCVPixelBufferCGImageCompatibilityKey:kCFBooleanTrue , kCVPixelBufferCGBitmapContextCompatibilityKey : kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) //3
        
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        // Core ML
        guard let prediction = try? model.prediction(image: pixelBuffer!) else {
            return
        }
        
        resultLabel.text = "可能是:\(prediction.classLabel)."
    }

}
