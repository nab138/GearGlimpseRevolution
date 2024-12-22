import ARKit
import SceneKit
import SceneKit.ModelIO

struct Robot {
  var url: URL
  var name: String
  var positionOffset: SCNVector3
  // Degrees
  var rotations: SCNVector3

  static let robot3044 = Robot.fromResources(
    name: "R0xstar (3044)", file: "R0xstar", offset: SCNVector3(0.35, -0.35, -0.875),
    rotations: SCNVector3Zero)
  static let kitBot = Robot.fromResources(
    name: "2024 KitBot", file: "2024KitBot", offset: SCNVector3(0.35, 0.1, -0.4),
    rotations: SCNVector3(0, 90, 0))

  static func fromResources(name: String, file: String, offset: SCNVector3, rotations: SCNVector3)
    -> Robot
  {
    return Robot(
      url: Bundle.main.url(forResource: file, withExtension: "usdz")!, name: name,
      positionOffset: offset, rotations: rotations)
  }

  static func getByName(_ name: String) -> Robot {
    switch name {
    case "R0xstar (3044)":
      return robot3044
    case "2024 KitBot":
      return kitBot
    default:
      return kitBot
    }
  }
}

class ARSceneView: ARSCNView {
  var fieldNode: SCNNode!
  var gamePieceModel: SCNNode!
  var gamePieceNodes: [SCNNode] = []
  var gamePiecePositions: [SCNVector3] = []
  var curDummyNode: SCNNode?
  var curContainerDummyNode: SCNNode?
  var curRobotNode: SCNNode?

  var referenceNode: SCNNode?

  let detector = VispDetector()
  var detectedImageLayer: CALayer?

  var imageView: UIImageView?

  var trajectoryNode: SCNLineNode?

  var hasPlacedField = false

  func loadModelFromResources(_ name: String) -> SCNNode? {
    let url = Bundle.main.url(forResource: name, withExtension: "usdz")!
    return loadModelFromURL(url)
  }

  func loadModelFromURL(_ url: URL) -> SCNNode? {
    let mdlAsset = MDLAsset(url: url)
    mdlAsset.loadTextures()
    let scene = SCNScene(mdlAsset: mdlAsset)
    return scene.rootNode
  }

  func loadRobot(_ robot: Robot) -> SCNNode? {
    guard let robotNode = loadModelFromURL(robot.url) else {
      return nil
    }
    if let curRobotNode = curRobotNode {
      curRobotNode.removeFromParentNode()
    }
    if let curDummyNode = curDummyNode {
      curDummyNode.removeFromParentNode()
    }
    if let curContainerDummyNode = curContainerDummyNode {
      curContainerDummyNode.removeFromParentNode()
    }
    if let referenceNode = referenceNode {
      referenceNode.removeFromParentNode()
    }
    curRobotNode = robotNode
    // This is used to rotate the translated model
    referenceNode = SCNNode()
    let dummyNode = SCNNode()
    // This is used to provide an easy container where other code can just translate and rotate the container
    let containerDummyNode = SCNNode()
    curContainerDummyNode = containerDummyNode
    curDummyNode = dummyNode
    robotNode.position = robot.positionOffset
    let radianRotations = SCNVector3(
      robot.rotations.x * .pi / 180, robot.rotations.y * .pi / 180, robot.rotations.z * .pi / 180)
    dummyNode.eulerAngles = radianRotations
    dummyNode.addChildNode(robotNode)
    containerDummyNode.addChildNode(dummyNode)
    scene.rootNode.addChildNode(containerDummyNode)
    fieldNode.addChildNode(referenceNode!)
    updateRobotNodeTransform()
    NSLog("Successfully loaded robot with name: \(robot.name)")
    return referenceNode
  }

  func updateRobotNodeTransform() {
    if let referenceNode = referenceNode {
      // Convert position from referenceNode's coordinate space to world coordinate space
      let positionInWorld = fieldNode.convertPosition(referenceNode.position, to: nil)

      // Convert rotation from referenceNode's coordinate space to world coordinate space
      let rotationInWorld = referenceNode.worldOrientation

      // Assign the world space position, rotation, and scale to curContainerDummyNode
      curContainerDummyNode?.position = positionInWorld
      curContainerDummyNode?.orientation = rotationInWorld
      curContainerDummyNode?.scale = fieldNode.scale
    }
  }

  func updateTrajectoryTransform() {
    if let trajectoryNode = trajectoryNode {
      trajectoryNode.position = fieldNode.position
      trajectoryNode.scale = fieldNode.scale
      trajectoryNode.eulerAngles = fieldNode.eulerAngles
    }
  }

  func drawTrajectory(points: [SCNVector3]) {
    guard points.count > 1 else { return }

    if trajectoryNode != nil {
      trajectoryNode?.removeFromParentNode()
    }

    if fieldNode != nil {
      trajectoryNode = SCNLineNode(with: points, radius: 0.04)
      trajectoryNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
      trajectoryNode?.isHidden = !hasPlacedField

      scene.rootNode.addChildNode(trajectoryNode!)

      updateTrajectoryTransform()
    }
  }

  func drawGamePieces(points: [SCNVector3]) {
    if points.count < gamePieceNodes.count {
      for i in points.count..<gamePieceNodes.count {
        gamePieceNodes[i].removeFromParentNode()
      }
      gamePieceNodes = Array(gamePieceNodes.prefix(points.count))
    }
    if points.count > gamePieceNodes.count {
      for i in gamePieceNodes.count..<points.count {
        let gamePieceNode = gamePieceModel.clone()
        gamePieceNode.position = points[i]
        gamePieceNodes.append(gamePieceNode)
        scene.rootNode.addChildNode(gamePieceNode)
      }
    }

    // Place instances of the model at each location
    for i in 0..<points.count {
      gamePieceNodes[i].position = points[i]
      gamePieceNodes[i].isHidden = !hasPlacedField
    }

    // save game piece positions
    gamePiecePositions = points

    // Update transforms
    updateGamePieceTransforms()
  }

  func updateGamePieceTransforms() {
    for i in 0..<gamePiecePositions.count {
      gamePieceNodes[i].position = fieldNode.convertPosition(gamePiecePositions[i], to: nil)
      gamePieceNodes[i].scale = fieldNode.scale
    }
  }



  @objc func handleOrientationChange() {
    DispatchQueue.main.async {
      self.updateDetectedImageLayerFrame()
    }
  }

  func updateDetectedImageLayerFrame() {
    guard let detectedImageLayer = self.detectedImageLayer else { return }
    detectedImageLayer.frame = self.bounds
  }

  func detectAprilTagsInScene(completion: @escaping (Bool) -> Void) {
    autoreleasepool {
      guard let uiImage = self.imageFrom(), let currentFrame = self.session.currentFrame else {
        completion(false)
        return
      }

      guard
        let detectedImage = self.detector.detectAprilTag(
          uiImage, px: Float(currentFrame.camera.intrinsics.columns.0.x),
          py: Float(currentFrame.camera.intrinsics.columns.1.y))
      else {
        if !(self.detectedImageLayer?.isHidden ?? false) {
          DispatchQueue.main.async {
            self.detectedImageLayer?.isHidden = true
          }
        }
        completion(false)
        return
      }

      DispatchQueue.main.async {
        if self.detectedImageLayer == nil {
          NotificationCenter.default.addObserver(
            self, selector: #selector(self.handleOrientationChange),
            name: UIDevice.orientationDidChangeNotification, object: nil)
          self.detectedImageLayer = CALayer()
          self.detectedImageLayer!.frame = self.bounds
          self.detectedImageLayer!.contentsGravity = .resizeAspectFill
          self.detectedImageLayer!.backgroundColor = UIColor.clear.cgColor
          self.layer.addSublayer(self.detectedImageLayer!)
        }
        self.detectedImageLayer!.contents = detectedImage.cgImage
        self.detectedImageLayer!.isHidden = false
        self.updateDetectedImageLayerFrame()
        completion(true)
      }
    }
  }

  func SCNVector3Distance(startPoint: SCNVector3, endPoint: SCNVector3) -> Float {
    let dx = endPoint.x - startPoint.x
    let dy = endPoint.y - startPoint.y
    let dz = endPoint.z - startPoint.z
    return sqrt(dx * dx + dy * dy + dz * dz)
  }

  func imageFrom() -> UIImage? {
    guard let currentFrame = self.session.currentFrame else {
      return nil
    }

    let pixelBuffer = currentFrame.capturedImage
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

    var transform: CGAffineTransform

    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
      switch windowScene.interfaceOrientation {
      case .portrait:
        transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
      case .landscapeLeft:
        transform = CGAffineTransform(rotationAngle: 0)
      case .landscapeRight:
        transform = CGAffineTransform(rotationAngle: CGFloat.pi)
      default:
        transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
      }
    } else {
      transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
    }

    transform = transform.scaledBy(x: -1, y: -1)

    let transformedCIImage = ciImage.transformed(by: transform)

    let context = CIContext(options: nil)
    guard let cgImage = context.createCGImage(transformedCIImage, from: transformedCIImage.extent)
    else {
      return nil
    }

    let image = UIImage(cgImage: cgImage)

    return image
  }
}
