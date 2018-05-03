//
//  ARRoomViewController.swift
//  flip
//
//  Created by Devin Lim on 4/19/18.
//  Copyright © 2018 Devin Lim. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ARRoomViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    private var imgSet : [String] = [String()]
    private var touchCount = 0
    private var path : UIBezierPath!
    let sqlCommand = SqlCommand()
    var ARObjectStats : [String:[String:Any]]?
    var roomItems : [String:SCNNode] = [String:SCNNode]()
    var keyNum : Int = 0
    var keys : [String] = [String]()
    @IBOutlet weak var selectedItemTitle: UIButton!
    @IBOutlet weak var toggleSelectedItem: UIButton!
    
    @IBAction func ToggleSelectedItemButtonPressed(_ sender: Any) {
        keyNum = (keyNum + 1) % (ARObjectStats?.keys.count)!
        selectedItemTitle.setTitle("Selected Item: \(keys[keyNum])", for: UIControlState.normal)
    }
    
    //var planes = [ARPlaneAnchor: PlaneNode]()
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedItemTitle.isHidden = false
        selectedItemTitle.setTitle("Look for a surface, then tap to create view.", for: UIControlState.normal)
        toggleSelectedItem.isHidden = true
        
        self.navigationController?.isNavigationBarHidden = false
        // Set the view's delegate
        sceneView.delegate = self
        sqlCommand.createTable()
        sqlCommand.selectObject()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // apple arkit supports horizontal only.
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    func initShape(){
        path.move(to: CGPoint(x: 0, y:0))
        path.addLine(to: CGPoint(x:0, y:0.2))
        path.addLine(to: CGPoint(x:0.3, y:0.2))
        path.addLine(to: CGPoint(x:0.3, y:0))
        let shape = SCNShape(path: path, extrusionDepth:0.2)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first{
            
            
            //location of where we touch on 2d screen
            let touchLocation = touch.location(in: sceneView)
            // to perform to get the 3D coordinate corresponding to the 2D coord.
            // 3d coord will only be considered when it is on the existing plane we detected.
            let results = sceneView.hitTest(touchLocation, types: .estimatedHorizontalPlane)
            
            // check if we got some result using hitTest.
            if let hitResult = results.first{
                if (touchCount == 0){
                    initRoom(hitResult: hitResult)
                } else {
                    moveItem(key: keys[keyNum], hitResult: hitResult)
                }
            }
        }
//        let table = boxNode.childNode(withName: "table", recursively: true)
//
//        let detectedObject = self.planes[planeAnchor]
//        let nodeId = detectedObject.name
//        print(nodeId)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touchCount > 0, let touch = touches.first{
            //location of where we touch on 2d screen
            let touchLocation = touch.location(in: sceneView)
            
            // to perform to get the 3D coordinate corresponding to the 2D coord.
            // 3d coord will only be considered when it is on the existing plane we detected.
            let results = sceneView.hitTest(touchLocation, types: .estimatedHorizontalPlane)
            
            // check if we got some result using hitTest.
            if let hitResult = results.first{
                moveItem(key: keys[keyNum], hitResult: hitResult)
            }
        }
    }
    
    func moveItem( key : String, hitResult : ARHitTestResult ){
        roomItems[key]?.worldPosition = SCNVector3(x:hitResult.worldTransform.columns.3.x,
                                                   y:-0.263,
                                                   z:hitResult.worldTransform.columns.3.z)
    }
    
    func initRoom(hitResult : ARHitTestResult){
        let boxScene = SCNScene(named: "art.scnassets/portal.scn")!
        if let boxNode = boxScene.rootNode.childNode(withName: "portal", recursively: true){
            boxNode.position = SCNVector3(x:hitResult.worldTransform.columns.3.x,
                                          y:hitResult.worldTransform.columns.3.y + 0.05,
                                          z:hitResult.worldTransform.columns.3.z)
            boxNode.eulerAngles = SCNVector3(x:0.0,
                                             y:-90.0,
                                             z:0.0)
            
            if imgSet.count > 4{
                if let roomNode = boxScene.rootNode.childNode(withName: "room", recursively: true){
                    for i in 0...imgSet.count - 1{
                        let img : UIImage = UIImage(named: imgSet[i])!
                        roomNode.geometry?.materials[i].diffuse.contents = img
                    }
                }
                for key in (ARObjectStats?.keys)!{
                    if let roomItem = boxScene.rootNode.childNode(withName: key, recursively: true){
                        roomItems[roomItem.name!] = roomItem
                        roomItem.position = setObjectPositionFromDictInSwift(objectKey: key)
                        //                            tableNode.eulerAngles = setObjectEulerInSwift(objectKey: key)
                        roomItem.scale = setObjectScaleFromDictInSwift(objectKey: key)
                        //                                roomItem.isHidden = false
                        keys.append(key)
                    }
                }
            }
            sceneView.scene.rootNode.addChildNode(boxNode)
            keyNum = 0
            selectedItemTitle.isHidden = false
            toggleSelectedItem.isHidden = false
            selectedItemTitle.setTitle("Selected Item: \(keys[keyNum])", for: UIControlState.normal)
            touchCount += 1
        }
    }
    
    func setObjectPositionFromDictInSwift( objectKey : String ) -> SCNVector3 {
        let floorYValues : [String:Float] = ["table" : -0.213,
                                             "toliet" : -0.063,
                                             "plant1" : -0.263,
                                             "chair" : -0.262]
        
        let result : SCNVector3 = SCNVector3(x: ( (ARObjectStats![objectKey]!["xpos"] as! Float) / 3.5 ) * -0.9,
                                             y: (floorYValues[objectKey])!,
                                             z: ( (ARObjectStats![objectKey]!["zpos"] as! Float) / 3.5 ) * 0.9 )
        print("***** \(objectKey) POSITION: \(result)")
        return result
    }
    
    func setObjectEulerInSwift( objectKey : String ) -> SCNVector3 { // this is really inconsistent for some reason...
        let result : SCNVector3 = SCNVector3(x: ( (ARObjectStats![objectKey]!["xrot"] as! Float) - 90 ),
                                             y: ( (ARObjectStats![objectKey]!["yrot"] as! Float) ),
                                             z: ( (ARObjectStats![objectKey]!["zrot"] as! Float) ) )
        print("***** \(objectKey) ROTATION: \(result)")
        return result
    }
    
    func setObjectScaleFromDictInSwift( objectKey : String ) -> SCNVector3 {
        let baseScaleValues : [String:Float] = ["table" : 0.016666667,
                                                "toliet" : 0.06,
                                                "plant1" : 0.04,
                                                "chair" : 0.033333333]
        
        let result : SCNVector3 = SCNVector3(x: ( (ARObjectStats![objectKey]!["xsca"] as! Float) * baseScaleValues[objectKey]! ),
                                             y: ( (ARObjectStats![objectKey]!["ysca"] as! Float) * baseScaleValues[objectKey]! ),
                                             z: ( (ARObjectStats![objectKey]!["zsca"] as! Float) * baseScaleValues[objectKey]! ) )
        print("***** \(objectKey) SCALE: \(result)")
        return result
    }
    
    //when horizontal plane is detected.
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor{
            let planeAnchor = anchor as! ARPlaneAnchor
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            let planeNode = SCNNode()
            planeNode.position = SCNVector3(x:planeAnchor.center.x,y:0,z:planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
            
            let gridMaterial = SCNMaterial()
            gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
            plane.materials = [gridMaterial]
            planeNode.geometry = plane
            //self.planes[planeAnchor] = planeNode
            node.addChildNode(planeNode)
        }
    }
    
    public func setImgSet( paramsImgSet : [String] ){
        imgSet.removeAll()
        for i in 0...paramsImgSet.count - 1{
            imgSet.append(((NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString) as String).appending(paramsImgSet[i]) )
        }
    }
    
    public func setARObjStats( ARObjectStats_param : [String:[String:Any]] ){
        ARObjectStats = ARObjectStats_param
    }
}
