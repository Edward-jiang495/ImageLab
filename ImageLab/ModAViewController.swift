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
//    face filters array
    var filtersEye : [CIFilter]! = nil
//    eye filters array
    var filtersMouth : [CIFilter]! = nil
//    mouth filter array
    
    @IBOutlet weak var hasSmile: UILabel!
//    smile label that shows text on smile
    
    lazy var videoManager:VideoAnalgesic! = {
//        create video analgesic
        let tmpManager = VideoAnalgesic(mainView: self.view)
        tmpManager.setCameraPosition(position: .front)
        return tmpManager
    }()
    
    lazy var detector:CIDetector! = {
        // create dictionary for face detection
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyHigh,
                            CIDetectorTracking:true, CIDetectorMaxFeatureCount: 256] as [String : Any]
//        add max feature number for multiple faces
        
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
//        hide the smile label by default
        
        self.view.backgroundColor = nil
//        background color to nil
        self.setupFilters()
//        set up filters
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
//        set running code
        
        if !videoManager.isRunning{
            videoManager.start()
//            start running
        }
    
    }
    override func viewDidDisappear(_ animated: Bool){
        
        DispatchQueue.main.async {
            self.videoManager.shutdown()

        }
        super.viewDidDisappear(animated)
        
    }
    
    
    //MARK: Setup filtering
    func setupFilters(){
        filters = []
//        filters for face
        
        let filterPinch = CIFilter(name:"CIBumpDistortionLinear")!
        filterPinch.setValue(100, forKey: "inputRadius")
//        set up face filters
        filters.append(filterPinch)
//        add to face filters array
        
        filtersEye = []
        let filtere = CIFilter(name: "CITwirlDistortion")!
        filtere.setValue(15, forKey: "inputRadius")
//        set up eye filter
        filtersEye.append(filtere)
//        add filter to eyes filter array
        
        filtersMouth = []
        let filterm = CIFilter(name: "CIHoleDistortion")!
        filterm.setValue(25, forKey: "inputRadius")
//        set up mouth filter
        filtersMouth.append(filterm)
//        add filter to mouth filter
        
        
    }
    
    //MARK: Apply filters and apply feature detectors
    func applyFiltersToFaces(inputImage:CIImage,features:[CIFaceFeature])->CIImage{
        var retImage = inputImage
        var filterCenter = CGPoint()
        
        for f in features {
            //set where to apply filter
//            loop through all faces get from camera
            filterCenter.x = f.bounds.midX
            filterCenter.y = f.bounds.midY
            if f.hasSmile{
//                smile detection
//                smile detected
                DispatchQueue.main.async {
//                    show smile label
                    self.hasSmile.isHidden = false;
                }
            }
            else{
//                no smile detected
                DispatchQueue.main.async {
//                    hide smile label
                    self.hasSmile.isHidden = true;
                }
            }
            if f.hasLeftEyePosition{
//                has left eye
                for filt in filtersEye{
                    filt.setValue(retImage, forKey: kCIInputImageKey)
                    filt.setValue(CIVector(cgPoint: (f.leftEyePosition)), forKey: "inputCenter")
//                    apply filters to left eye
                    retImage = filt.outputImage!
                    
                }
//                print("Found left eye at \(f.leftEyePosition)")

                
                
            }
            if f.hasRightEyePosition{
//                has right eye
                for filt in filtersEye{
                    filt.setValue(retImage, forKey: kCIInputImageKey)
                    filt.setValue(CIVector(cgPoint: (f.rightEyePosition)), forKey: "inputCenter")
                    // apply filters to right eye
                    retImage = filt.outputImage!
                    
                }
//                print("Found right eye at \(f.rightEyePosition)")

                
            }
            
            if f.hasMouthPosition{
//                has mouth position
                for filt in filtersMouth{
                    filt.setValue(retImage, forKey: kCIInputImageKey)
                    filt.setValue(CIVector(cgPoint: (f.mouthPosition)), forKey: "inputCenter")
                    // apply filters to mouth
                    retImage = filt.outputImage!
                    
                }
//                print("Found mouth at \(f.mouthPosition)")

                
            }
            
         
            //do for each filter (assumes all filters have property, "inputCenter")
            for filt in filters{
//                apply filters to face
                filt.setValue(retImage, forKey: kCIInputImageKey)
                filt.setValue(CIVector(cgPoint: filterCenter), forKey: "inputCenter")
                retImage = filt.outputImage!
            }
        }
        return retImage
    }
    
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation, CIDetectorSmile: true] as [String : Any]
//       add detector for smile
//        set options for detector
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
    
    //MARK: Process image output
    func processImage(inputImage:CIImage) -> CIImage{
        
        // detect faces
        let faces = getFaces(img: inputImage)
//        get faces
//        print(faces.count)
        
        // if no faces, just return original image
        if faces.count == 0 { return inputImage }
        
        //otherwise apply the filters to the faces
        return applyFiltersToFaces(inputImage: inputImage, features: faces)
//        apply fitlers to faces if face number > 0
    }
    

}
