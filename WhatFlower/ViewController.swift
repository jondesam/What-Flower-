//
//  ViewController.swift
//  WhatFlower
//
//  Created by MyMac on 2019-02-10.
//  Copyright © 2019 Apex. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage
import ColorThiefSwift

class ViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    var pickedImage: UIImage? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        //        let image = info[.originalImage] as? UIImage
        //
        //        imageView.image = image
        
        if let userPickedImage = info[.editedImage] as? UIImage {
            
            //imageView.image = userPickedImage
            
            guard let convertedCIImage = CIImage(image: userPickedImage) else {
                fatalError("could not convert to CIImage")
            }
            detect(image: convertedCIImage)
            
            pickedImage = userPickedImage
            
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    func detect(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreML Model Failed")
        }
        
        let request = VNCoreMLRequest(model: model) { (vnRequest, error) in
            
            
            guard let classification = vnRequest.results?.first as? VNClassificationObservation else {
                fatalError("No Classification")
            }
            
            
            
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }
        
        
        
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try  handler.perform([request])
        }
        catch {
            print(error)
        }
        
        
    }
    
    
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize": "500"
        ]
        
        //        Alamofire.request(wikipediaURl, method: .get, parameters: parameters ).responseJSON { (<#DataResponse<Any>#>) in
        //            <#code#>
        //        }
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters ).responseJSON { (response) in
            
            if response.result.isSuccess {
                print("Got the wikidepia info")
               // print(JSON(response.result.value))
                
                let flowerJSON:JSON = JSON(response.result.value!)
                
                let pageId = flowerJSON["query"]["pageids"][0].stringValue
                
                let description = flowerJSON["query"]["pages"][pageId]["extract"]
                
                let flowerImageURL = flowerJSON["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
                //SDWebImage
                self.imageView.sd_setImage(with: URL(string: flowerImageURL), completed: nil)
                
      
                self.descriptionLabel.text = description.stringValue
            }
            
        }
        
        
    }
    
    
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
}

