//
//  ARController.swift
//  unitySwiftTest
//
//  Created by Devin Lim on 2/27/18.
//  Copyright © 2018 Jeremy Ronquillo. All rights reserved.
//

import UIKit
public extension UIWindow{
    func captureScreen() -> UIImage?{
        UIGraphicsBeginImageContextWithOptions(self.frame.size, self.isOpaque, UIScreen.main.scale)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

class ARController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
//    @IBOutlet var rotateSwitch: UISwitch!
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    var imagePicker: UIImagePickerController!
    
    @IBOutlet weak var btnBack: UIButton!
    @objc func handleUnityReady() {
        btnBack.isHidden = false
        showUnitySubView()
        
    }
    @IBAction func ARViewBackAction(_ sender: UIButton) {
        appDelegate?.stopUnity()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func SFViewBackAction(_ sender: Any) {
        print("SF view exited.")
        self.dismiss(animated: true, completion: nil)
    }
    
    func showUnitySubView() {
        if let unityView = UnityGetGLView() {
            // insert subview at index 0 ensures unity view is behind current UI view
            view?.insertSubview(unityView, at: 0)
            
            unityView.translatesAutoresizingMaskIntoConstraints = false
            let views = ["view": unityView]
            let w = NSLayoutConstraint.constraints(withVisualFormat: "|-0-[view]-0-|", options: [], metrics: nil, views: views)
            let h = NSLayoutConstraint.constraints(withVisualFormat: "V:|-75-[view]-0-|", options: [], metrics: nil, views: views)
            view.addConstraints(w + h)
        }
    }
    func showUnity() {
        appDelegate?.startUnity()
        NotificationCenter.default.addObserver(self, selector: #selector(handleUnityReady), name: NSNotification.Name("UnityReady"), object: nil)
        handleUnityReady()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear( animated )
        showUnity()

    }
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(UnityFinishedTakingScreenshot(_:)), name: NSNotification.Name("UnityFinishedTakingScreenshot"), object: nil)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func UnityFinishedTakingScreenshot(_ n: NSNotification) {
//        usleep(100000) //will sleep for .1 seconds
        print( "-> UnityFinishedTakingScreenshot()" )
        if let imgName = n.userInfo?["filename"] as? NSString {
            let window:UIWindow! = UIApplication.shared.keyWindow
            let image = window.captureScreen()
            saveImageToDirectory(image!)
            
            appDelegate?.stopUnity()
            
            let sfViewController:StillFrameViewController = self.storyboard?.instantiateViewController(withIdentifier: "StillFrameViewController") as! StillFrameViewController
            // This sfViewController.imageName should use the returned image name from the Screenshot() on unity.
            sfViewController.imageName = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent( (imgName as String!) )
            self.navigationController?.pushViewController(sfViewController, animated: true)
//            self.dismiss(animated: true, completion: nil)
        }
        else{
            print("THERE WAS A FAILURE THERE WAS A FAILURE THERE WAS A FAILURE THERE WAS A FAILURE THERE WAS A FAILURE THERE WAS A FAILURE")
        }
        
        
    }
    
    
    @IBAction func takePhoto(_ sender: Any) {
        UnityPostMessage("NATIVE_BRIDGE", "Screenshot", "false") // false means don't include items
    }
    
    
    func saveImageToDirectory(_ chosenImage:UIImage)->String{
        let paths = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("test.jpg")
        let url = NSURL.fileURL(withPath: paths)
        
        do {
            try UIImageJPEGRepresentation(chosenImage, 1.0)?.write(to: url, options: .atomic)
            return String.init(paths)
        } catch {
            print(error)
            print("file cant not be save at path \(paths), with error : \(error)");
            return paths
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePicker.dismiss(animated: false, completion: nil)

        
        let fileManager = FileManager.default
        let paths = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("test.jpg")
        let image = UIImage(named: "test.jpg")
        print(paths)
        let imageData = UIImageJPEGRepresentation(info[UIImagePickerControllerOriginalImage] as! UIImage, 0.5)
        fileManager.createFile(atPath: paths as String, contents: imageData, attributes: nil)
        
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
