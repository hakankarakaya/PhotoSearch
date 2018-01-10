//
//  ViewController.swift
//

import UIKit
import CoreML
import Vision
import AVFoundation

class ViewController: UIViewController, FrameExtractorDelegate {
    
    var frameExtractor: FrameExtractor!
    
    @IBOutlet weak var predictLabel: UILabel!
    @IBOutlet weak var previewImage: UIImageView!
    
    var settingImage = false
    var compiledURL:URL!
    let vowels: [Character] = ["a", "e", "i", "o", "u"]
    
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
        self.previewImage.image = resizeImageWith(image: image, newSize:CGSize(width: 224, height: 224))
        if let cgImage = resizeImageWith(image: image, newSize:CGSize(width: 224, height: 224)).cgImage, !settingImage {
            settingImage = true
            DispatchQueue.global(qos: .userInteractive).async {[unowned self] in
                self.currentImage = CIImage(cgImage: cgImage)
            }
        }
    }
    
    func resizeImageWith(image: UIImage, newSize: CGSize) -> UIImage {
        
        let horizontalRatio = newSize.width / image.size.width
        let verticalRatio = newSize.height / image.size.height
        
        let ratio = max(horizontalRatio, verticalRatio)
        let newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        var newImage: UIImage
        
        if #available(iOS 10.0, *) {
            let renderFormat = UIGraphicsImageRendererFormat.default()
            renderFormat.opaque = false
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: newSize.width, height: newSize.height), format: renderFormat)
            newImage = renderer.image {
                (context) in
                image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: newSize.width, height: newSize.height), true, 0)
            image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
            newImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }
        
        return newImage
    }
    
    func detectScene(image: CIImage) {
        do {
//             You have to add the file whose name is changed from KerasMNIST.mlmodel to KerasMNIST.bin to app target.
//             In order to avoid that Xcode compiles a mlmodel file automatcally.
            let documentDirectoryURL =  try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let compiledURL = try MLModel.compileModel(at: documentDirectoryURL.appendingPathComponent("cars.zip"))
            
            let coremlModel = try MLModel(contentsOf: compiledURL)
            
            predictLabel.text = "detecting scene..."
            guard let model = try? VNCoreMLModel(for: coremlModel) else {
                fatalError("can't load Places ML model")
            }
            
            // Create a Vision request with completion handler
            let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                guard let results = request.results as? [VNClassificationObservation],
                    let topResult = results.first else {
                        fatalError("unexpected result type from VNCoreMLRequest")
                }
                
                // Update UI on main queu
                let article = (self?.vowels.contains(topResult.identifier.first!))! ? "an" : "a"
                DispatchQueue.main.async { [weak self] in
                    if(topResult.confidence > 0.8){
                        self?.predictLabel.text = "\(Int(topResult.confidence * 100))% it's \(article) \(topResult.identifier)"
                    }else
                    {
                        self?.predictLabel.text = ""
                    }
                    self?.settingImage = false
                }
            }
         
            // Run the Core ML GoogLeNetPlaces classifier on global dispatch queue
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

