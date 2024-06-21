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
  var curDummyNode: SCNNode?
  var curContainerDummyNode: SCNNode?
  var curRobotNode: SCNNode?

  var referenceNode: SCNNode?

  let detector = VispDetector()
  var detectedImageLayer: CALayer?

  var imageView: UIImageView?

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
          self.detectedImageLayer = CALayer()
          self.detectedImageLayer!.frame = self.bounds
          self.detectedImageLayer!.contentsGravity = .resizeAspectFill
          self.detectedImageLayer!.backgroundColor = UIColor.clear.cgColor
          self.layer.addSublayer(self.detectedImageLayer!)
        }
        self.detectedImageLayer!.contents = detectedImage.cgImage
        self.detectedImageLayer!.isHidden = false
        completion(true)
      }
    }
  }

  func drawTrajectory(points: [SCNVector3]) {
    NSLog("Drawing trajectory with \(points.count) points. First point: \(points.first!)")
    guard points.count > 1 else { return }

    for i in 0..<points.count - 1 {
      let startPoint = points[i]
      let endPoint = points[i + 1]

      // Calculate the distance between points
      let distance = SCNVector3Distance(startPoint: startPoint, endPoint: endPoint)

      // Create a cylinder with the distance as the height
      let cylinder = SCNCylinder(radius: 0.005, height: CGFloat(distance))
      cylinder.radialSegmentCount = 6  // Makes the cylinder look more like a line
      cylinder.firstMaterial?.diffuse.contents = UIColor.red  // Set color

      // Create a node for the cylinder
      let cylinderNode = SCNNode(geometry: cylinder)

      // Calculate midpoint for positioning
      let midPoint = SCNVector3(
        x: (startPoint.x + endPoint.x) / 2,
        y: (startPoint.y + endPoint.y) / 2,
        z: (startPoint.z + endPoint.z) / 2)
      cylinderNode.position = midPoint

      // Calculate the angle between the points
      let dx = endPoint.x - startPoint.x
      let dy = endPoint.y - startPoint.y
      let dz = endPoint.z - startPoint.z
      let angle = atan2(dy, sqrt(dx * dx + dz * dz))

      // Rotate the cylinder to align with the two points
      cylinderNode.eulerAngles.x = Float.pi / 2  // Adjust for cylinder's default orientation
      cylinderNode.eulerAngles.y = 0
      cylinderNode.eulerAngles.z = -angle

      // Add the cylinder to the fieldNode
      fieldNode.addChildNode(cylinderNode)
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

    var transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
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
