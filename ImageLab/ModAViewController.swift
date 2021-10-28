//
//  ModAViewController.swift
//  CoreImageLab
//
//  Created by Zhengran Jiang on 10/22/21.
//

import UIKit
import AVFoundation


class ModAViewController: UIViewController {
    //mod a face detection
    //MARK: Class Properties
    var filters : [CIFilter]! = nil
    var filtersEye : [CIFilter]! = nil
    var filtersMouth : [CIFilter]! = nil
    
    @IBOutlet weak var hasSmile: UILabel!
    
    
    lazy var videoManager:VideoAnalgesic! = {
        let tmpManager = VideoAnalgesic(mainView: self.view)
        tmpManager.setCameraPosition(position: .front)
        return tmpManager
    }()
    
    lazy var detector:CIDetector! = {
        // create dictionary for face detection
        // HINT: you need to manipulate these properties for better face detection efficiency
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyHigh,
                            CIDetectorTracking:true] as [String : Any]
        
        // setup a face detector in swift
        let detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: self.videoManager.getCIContext(), // perform on the GPU is possible
            options: (optsDetector as [String : AnyObject]))
        
        return detector
    }()
    
    lazy var detectorEye:CIDetector! = {
        // create dictionary for face detection
        // HINT: you need to manipulate these properties for better face detection efficiency
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyHigh,
                            CIDetectorTracking:true] as [String : Any]
        
        // setup a face detector in swift
        let detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: self.videoManager.getCIContext(), // perform on the GPU is possible
            options: (optsDetector as [String : AnyObject]))
        
        return detector
    }()
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hasSmile.isHidden = true;
        
        self.view.backgroundColor = nil
        self.setupFilters()
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
    
    }
    
    //MARK: Setup filtering
    func setupFilters(){
        filters = []
        
        let filterPinch = CIFilter(name:"CIBumpDistortionLinear")!
//        filterPinch.setValue(-0.5, forKey: "inputScale")
//        filterPinch.setValue(75, forKey: "inputRadius")
        filters.append(filterPinch)
        
        filtersEye = []
        let filtere = CIFilter(name: "CITwirlDistortion")!
//        filtere.setValue(-0.5, forKey: "inputScale")
        filtere.setValue(25, forKey: "inputRadius")
        filtersEye.append(filtere)
        
        filtersMouth = []
        let filterm = CIFilter(name: "CIHoleDistortion")!
//        filterm.setValue(-0.5, forKey: "inputScale")
        filterm.setValue(25, forKey: "inputRadius")
        filtersMouth.append(filterm)
        
        
    }
    
    //MARK: Apply filters and apply feature detectors
    func applyFiltersToFaces(inputImage:CIImage,features:[CIFaceFeature])->CIImage{
        var retImage = inputImage
        var filterCenter = CGPoint()
        
        for f in features {
            //set where to apply filter
            filterCenter.x = f.bounds.midX
            filterCenter.y = f.bounds.midY
            if f.hasSmile{
                print("HAS SMILE ")
                DispatchQueue.main.async {
                    self.hasSmile.isHidden = false;
                }
            }
            else{
                DispatchQueue.main.async {
                    self.hasSmile.isHidden = true;
                }
            }
            if f.hasLeftEyePosition{
                for filt in filtersEye{
                    filt.setValue(retImage, forKey: kCIInputImageKey)
                    filt.setValue(CIVector(cgPoint: (f.leftEyePosition)), forKey: "inputCenter")
                    // could also manipulate the radius of the filter based on face size!
                    retImage = filt.outputImage!
                    
                }
                print("Found left eye at \(f.leftEyePosition)")

                
                
            }
            if f.hasRightEyePosition{
                for filt in filtersEye{
                    filt.setValue(retImage, forKey: kCIInputImageKey)
                    filt.setValue(CIVector(cgPoint: (f.rightEyePosition)), forKey: "inputCenter")
                    // could also manipulate the radius of the filter based on face size!
                    retImage = filt.outputImage!
                    
                }
                print("Found right eye at \(f.rightEyePosition)")

                
            }
            
            if f.hasMouthPosition{
                for filt in filtersMouth{
                    filt.setValue(retImage, forKey: kCIInputImageKey)
                    filt.setValue(CIVector(cgPoint: (f.mouthPosition)), forKey: "inputCenter")
                    // could also manipulate the radius of the filter based on face size!
                    retImage = filt.outputImage!
                    
                }
                print("Found mouth at \(f.mouthPosition)")

                
            }
            
         
            //do for each filter (assumes all filters have property, "inputCenter")
            for filt in filters{
                filt.setValue(retImage, forKey: kCIInputImageKey)
                filt.setValue(CIVector(cgPoint: filterCenter), forKey: "inputCenter")
                // could also manipulate the radius of the filter based on face size!
                retImage = filt.outputImage!
            }
        }
        return retImage
    }
    
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation, CIDetectorSmile: true] as [String : Any]
//        let optsFace = [CIDetectorSmile: true]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
    
    //MARK: Process image output
    func processImage(inputImage:CIImage) -> CIImage{
        
        // detect faces
        let faces = getFaces(img: inputImage)
        
        // if no faces, just return original image
        if faces.count == 0 { return inputImage }
        
        //otherwise apply the filters to the faces
        return applyFiltersToFaces(inputImage: inputImage, features: faces)
    }
    

}
