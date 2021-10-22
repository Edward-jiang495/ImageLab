//
//  ViewController.swift
//  ImageLab
//
//  Created by Eric Larson
//  Copyright © Eric Larson. All rights reserved.
//
import UIKit
import AVFoundation

class ViewController: UIViewController {

    //MARK: Class Properties
    var filters: [CIFilter]! = nil
    var videoManager: VideoAnalgesic! = nil
    let pinchFilterIndex = 2
    var detector: CIDetector! = nil
    let bridge = OpenCVBridge()

    var timer = Timer()
    var timerToggle: Bool = false
    var index = 0;

    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    //MARK: Outlets in view
    @IBOutlet weak var flashSlider: UISlider!
    @IBOutlet weak var stageLabel: UILabel!

    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        timerToggle = false

        self.view.backgroundColor = nil



//        use the back camera
        self.videoManager = VideoAnalgesic(mainView: self.view)
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)



        self.videoManager.setProcessingBlock(newProcessBlock: self.processImageSwift)

        if !videoManager.isRunning {
            videoManager.start()
        }

    }

    var timeToTurnOff = Date()

    //MARK: Process image output
    func processImageSwift(inputImage: CIImage) -> CIImage {
        var retImage = inputImage
        self.bridge.setTransforms(self.videoManager.transform)
        self.bridge.setImage(retImage,
                             withBounds: retImage.extent, // the first face bounds
                             andContext: self.videoManager.getCIContext())



        let result = self.bridge.processFinger();
        let detected = Date()
        if result
        {
            // detected
            timeToTurnOff = detected.addingTimeInterval(1)
        }
        
        if detected < timeToTurnOff
        {
            DispatchQueue.main.async() {
                self.cameraButton.isEnabled = false
                self.flashButton.isEnabled = false
                self.videoManager.turnOnFlashwithLevel(1.0)
            }
        }
        else {
            DispatchQueue.main.async() {
                self.cameraButton.isEnabled = true
                self.flashButton.isEnabled = true
                
                self.videoManager.turnOffFlash()
            }
        }
        

//        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(test), userInfo: nil, repeats: true)
//        timer.fire()
//
//
//        if(result) {
//            //finger detected
//            DispatchQueue.main.async() {
//                self.cameraButton.isEnabled = false
//                self.flashButton.isEnabled = false
//                if(self.timerToggle == true) {
//                    self.videoManager.turnOnFlashwithLevel(1.0)
//                    self.timerToggle = false
//                }
//
//            }
//
////            self.videoManager.turnOnFlashwithLevel(1)
//
//        }
//        else {
//            //no finger detected
//            DispatchQueue.main.async() {
//                self.cameraButton.isEnabled = true
//                self.flashButton.isEnabled = true
//                if(self.timerToggle == true) {
//                    self.videoManager.turnOffFlash()
//                    self.timerToggle = false
//
//
//                }
//            }
//        }
        retImage = self.bridge.getImageComposite() // get back opencv processed part of the image (overlayed on original)

        return retImage
    }

    //MARK: Setup Face Detection

//    func getFaces(img:CIImage) -> [CIFaceFeature]{
//        // this ungodly mess makes sure the image is the correct orientation
//        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation]
//        // get Face Features
//        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
//
//    }


    // change the type of processing done in OpenCV
//    @IBAction func swipeRecognized(_ sender: UISwipeGestureRecognizer) {
//        switch sender.direction {
//        case .left:
//            self.bridge.processType += 1
//        case .right:
//            self.bridge.processType -= 1
//        default:
//            break
//
//        }
//
//        stageLabel.text = "Stage: \(self.bridge.processType)"
//
//    }

    //MARK: Convenience Methods for UI Flash and Camera Toggle
    @IBAction func flash(_ sender: AnyObject) {
        if(self.videoManager.toggleFlash()) {
            self.flashSlider.value = 1.0
        }
        else {
            self.flashSlider.value = 0.0
        }
    }

    @IBAction func switchCamera(_ sender: AnyObject) {
        self.videoManager.toggleCameraPosition()
    }

    @IBAction func setFlashLevel(_ sender: UISlider) {
        if(sender.value > 0.0) {
            let val = self.videoManager.turnOnFlashwithLevel(sender.value)
            if val {
                print("Flash return, no errors.")
            }
        }
        else if(sender.value == 0.0) {
            self.videoManager.turnOffFlash()
        }
    }

    @objc
    func test() {
        self.timerToggle = !self.timerToggle
        print("HERE")
    }
}
