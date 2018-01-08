//
//  ViewController.swift
//

import UIKit
import CoreML
import Vision
import AVFoundation

class ViewController: UIViewController, FrameExtractorDelegate {
    
    var frameExtractor: FrameExtractor!
    
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var iSee: UILabel!
    
    var settingImage = false
    var compiledURL:URL!
    
    var currentImage: CIImage? {
        didSet {
            if let image = currentImage{
                self.detectScene(image: image)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        do{
            let documentDirectoryURL =  try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            compiledURL = try MLModel.compileModel(at: documentDirectoryURL.appendingPathComponent("cars.zip"))
        }catch{
            print(error)
        }
        
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self
    }
    
    func captured(image: UIImage) {
        self.previewImage.image = image
        if let cgImage = image.cgImage, !settingImage {
            settingImage = true
            DispatchQueue.global(qos: .userInteractive).async {[unowned self] in
                self.currentImage = CIImage(cgImage: cgImage)
            }
        }
    }
    
    func detectScene(image: CIImage) {
        do {
            // You have to add the file whose name is changed from KerasMNIST.mlmodel to KerasMNIST.bin to app target.
            // In order to avoid that Xcode compiles a mlmodel file automatcally.
//            let documentDirectoryURL =  try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
//            let compiledURL = try MLModel.compileModel(at: documentDirectoryURL.appendingPathComponent("cars.zip"))
            
            let coremlModel = try MLModel(contentsOf: compiledURL)
            
            guard let model = try? VNCoreMLModel(for: coremlModel) else {
                fatalError()
            }
            let request = VNCoreMLRequest(model: model) { [unowned self] request, error in
                guard let results = request.results as? [VNClassificationObservation],
                    let _ = results.first else {
                        self.settingImage = false
                        return
                }
                
                DispatchQueue.main.async { [unowned self] in
                    if let first = results.first {
                        if Int(first.confidence * 100) > 1 {
                            self.iSee.text = "I see \(first.identifier)"
                            self.settingImage = false
                        }
                    }
                    //        results.forEach({ (result) in
                    //          if Int(result.confidence * 100) > 1 {
                    //            self.settingImage = false
                    //            print("\(Int(result.confidence * 100))% it's \(result.identifier) ")
                    //          }
                    //        })
                    // print("********************************")
                    
                }
            }
            let handler = VNImageRequestHandler(ciImage: image)
            DispatchQueue.global(qos: .userInteractive).async {
                do {
                    try handler.perform([request])
                } catch {
                    print(error)
                }
            }
        } catch {
            print(error)
        }
    }
}

