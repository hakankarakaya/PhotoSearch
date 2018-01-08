//
//  DownloadViewController.swift
//

import UIKit

class DownloadViewController: UIViewController, URLSessionDownloadDelegate, UIDocumentInteractionControllerDelegate {

    var downloadTask: URLSessionDownloadTask!
    var backgroundSession: URLSession!

//    @IBAction func startDownload(_ sender: AnyObject) {
//        let url = URL(string: "http://www.pcarsiv.com/cars.zip")!
//        downloadTask = backgroundSession.downloadTask(with: url)
//        downloadTask.resume()
//    }
//    @IBAction func pause(_ sender: AnyObject) {
//        if downloadTask != nil{
//            downloadTask.suspend()
//        }
//    }
//    @IBAction func resume(_ sender: AnyObject) {
//        if downloadTask != nil{
//            downloadTask.resume()
//        }
//    }
//    @IBAction func cancel(_ sender: AnyObject) {
//        if downloadTask != nil{
//            downloadTask.cancel()
//        }
//    }
    
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet weak var statusLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backgroundSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "backgroundSession")
        backgroundSession = Foundation.URLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)
        progressView.setProgress(0.0, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        CheckModelFile();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func CheckModelFile() {
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectoryPath:String = path[0]
        let fileManager = FileManager()
        let destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath.appendingFormat("/cars.zip"))
        
        if fileManager.fileExists(atPath: destinationURLForFile.path){
            let uiAlert = UIAlertController(title: "Blue Eye", message: "Found the model. Download again?", preferredStyle: UIAlertControllerStyle.alert)
            self.present(uiAlert, animated: true, completion: nil)
            
            uiAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                self.statusLabel.text = "Downloading model please wait..."
                let url = URL(string: "http://www.pcarsiv.com/cars.zip")!
                self.downloadTask = self.backgroundSession.downloadTask(with: url)
                self.downloadTask.resume()
            }))
            uiAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { action in
                self.statusLabel.text = "Found the model."
                self.progressView.setProgress(1.0, animated: true)
                
                if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as? ViewController
                {
                    self.present(vc, animated: true, completion: nil)
                }
            }))
        }else{
            statusLabel.text = "Downloading model please wait..."
            let url = URL(string: "http://www.pcarsiv.com/cars.zip")!
            downloadTask = backgroundSession.downloadTask(with: url)
            downloadTask.resume()
        }
    }
    
    func showFileWithPath(path: String){
        let isFileFound:Bool? = FileManager.default.fileExists(atPath: path)
        if isFileFound == true{
            let viewer = UIDocumentInteractionController(url: URL(fileURLWithPath: path))
            viewer.delegate = self
            viewer.presentPreview(animated: true)
        }
    }
    
    func getDirectoryPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    //MARK: URLSessionDownloadDelegate
    // 1
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL){
        
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectoryPath:String = path[0]
        let fileManager = FileManager()
        let destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath.appendingFormat("/cars.zip"))
        
        if fileManager.fileExists(atPath: destinationURLForFile.path){
            statusLabel.text = "Found the model."
            progressView.setProgress(1.0, animated: true)
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as? ViewController
            {
                present(vc, animated: true, completion: nil)
            }
        }else{
            do {
                try fileManager.moveItem(at: location, to: destinationURLForFile)
                if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as? ViewController
                {
                    present(vc, animated: true, completion: nil)
                }
            }catch{
                print("An error occurred while moving file to destination url")
            }
        }
    }
    // 2
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64){
        progressView.setProgress(Float(totalBytesWritten)/Float(totalBytesExpectedToWrite), animated: true)
    }
    
    //MARK: URLSessionTaskDelegate
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?){
        downloadTask = nil
        progressView.setProgress(0.0, animated: true)
        if (error != nil) {
            print(error!.localizedDescription)
        }else{
            print("The task finished transferring data successfully")
        }
    }
    
    //MARK: UIDocumentInteractionControllerDelegate
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController
    {
        return self
    }
}

