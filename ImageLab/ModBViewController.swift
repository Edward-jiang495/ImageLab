//
//  ModBViewController.swift
//  CoreImageLab
//
//  Created by Zhengran Jiang on 10/22/21.




import UIKit
import AVFoundation

class ModBViewController: UIViewController {

    lazy var videoManager:VideoAnalgesic! = {
         let tmpManager = VideoAnalgesic(mainView: self.view)
         tmpManager.setCameraPosition(position: .back)
         return tmpManager
     }()
    let bridge = OpenCVBridge()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = nil
//        use the back camera
    
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImageSwift)

        if !videoManager.isRunning{
            videoManager.start()
        }

        // Do any additional setup after loading the view.
    }
    
    func processImageSwift(inputImage:CIImage) -> CIImage{
        //do i need to deallocate video analegsic
        self.videoManager.turnOnFlashwithLevel(0.3)

        var retImage = inputImage
        self.bridge.setTransforms(self.videoManager.transform)
        self.bridge.setImage(retImage,
                             withBounds: retImage.extent, // the first face bounds
                             andContext: self.videoManager.getCIContext())
        let result = self.bridge.processFinger();

        retImage = self.bridge.getImageComposite() // get back opencv processed part of the image (overlayed on original)

  
        return retImage
    }
    
    override func viewDidDisappear(_ animated: Bool){
        //does not work after going to larson office hour
        //no idea why
        //FLASH not turning off
        DispatchQueue.main.async {
            self.videoManager.turnOnFlashwithLevel(0)
            self.videoManager.shutdown()
//            self.videoManager.setProcessingBlock(newProcessBlock: nil)
//            self.videoManager = nil
        }
//        sleep(1)
       


        super.viewDidDisappear(animated)
        print("HERE")
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
