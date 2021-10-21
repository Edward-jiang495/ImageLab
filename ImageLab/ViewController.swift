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


    //MARK: Process image output
    func processImageSwift(inputImage: CIImage) -> CIImage {

        // detect faces
//        let f = getFaces(img: inputImage)
//
//        // if no faces, just return original image
//        if f.count == 0 { return inputImage }
//
        var retImage = inputImage

        // if you just want to process on separate queue use this code
        // this is a NON BLOCKING CALL, but any changes to the image in OpenCV cannot be displayed real time
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) { () -> Void in
//            self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())
//            self.bridge.processImage()
//        }

        // use this code if you are using OpenCV and want to overwrite the displayed image via OpenCV
        // this is a BLOCKING CALL
//        self.bridge.setTransforms(self.videoManager.transform)
//        self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())
//        self.bridge.processImage()
//        retImage = self.bridge.getImage()

        //HINT: you can also send in the bounds of the face to ONLY process the face in OpenCV
        // or any bounds to only process a certain bounding region in OpenCV
        self.bridge.setTransforms(self.videoManager.transform)
        self.bridge.setImage(retImage,
                             withBounds: retImage.extent, // the first face bounds
                             andContext: self.videoManager.getCIContext())

//        self.bridge.processImage()
        let result = self.bridge.processFinger()

        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(test), userInfo: nil, repeats: true)
        timer.fire()


        if(result) {
            //finger detected
            DispatchQueue.main.async() {
                self.cameraButton.isEnabled = false
                self.flashButton.isEnabled = false
                if(self.timerToggle == true) {
                    self.videoManager.turnOnFlashwithLevel(1.0)
                    self.timerToggle = false
                }

            }

//            self.videoManager.turnOnFlashwithLevel(1)

        }
        else {
            //no finger detected
            DispatchQueue.main.async() {
                self.cameraButton.isEnabled = true
                self.flashButton.isEnabled = true
                if(self.timerToggle == true) {
                    self.videoManager.turnOffFlash()
                    self.timerToggle = false


                }
            }
        }
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
