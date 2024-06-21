import ARKit
import SceneKit
import SceneKit.ModelIO
import UIKit

class RootViewController: UIViewController, UIGestureRecognizerDelegate, ARSessionDelegate,
  ARSCNViewDelegate
{
  // AR elements
  var sceneView: ARSceneView!
  var robotNode: SCNNode!
  var hasPlacedField = false

  // NetworkTables
  var NTHandler: NetworkTablesHandler!

  // UI elements
  var statusLabel: PaddedLabel!
  var instructionLabel: PaddedLabel!
  var openSettingsLabel: UILabel!

  // Variables for AprilTags
  var shouldDetectAprilTags = true
  var lastUpdateTime: TimeInterval?
  let detectionPeriod = 0.05
  let noDetectionPeriod = 0.5
  var failedOnce = false
  var period = 0.5
  var isDetectingAprilTags = false

  // Command Scheduler
  var scheduler: CommandScheduler!

  override func loadView() {
    super.loadView()

    sceneView = ARSceneView(frame: UIScreen.main.bounds)
    sceneView.autoenablesDefaultLighting = true
    self.view.addSubview(sceneView)
    sceneView.session.delegate = self
    sceneView.delegate = self

    instructionLabel = PaddedLabel()
    instructionLabel.font = UIFont.systemFont(ofSize: 18)
    instructionLabel.textColor = UIColor.white
    instructionLabel.backgroundColor = UIColor.darkGray.withAlphaComponent(0.65)
    instructionLabel.text = "Move iPhone to start"
    instructionLabel.translatesAutoresizingMaskIntoConstraints = false
    instructionLabel.layer.cornerRadius = 10
    instructionLabel.layer.masksToBounds = true
    instructionLabel.topInset = 10
    instructionLabel.bottomInset = 10
    instructionLabel.leftInset = 15
    instructionLabel.rightInset = 15

    self.view.addSubview(instructionLabel)

    NSLayoutConstraint.activate([
      instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      instructionLabel.topAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
    ])

    statusLabel = PaddedLabel()

    statusLabel.text = "NT: Disconnected"
    statusLabel.font = UIFont.systemFont(ofSize: 14)
    statusLabel.textColor = UIColor.white
    statusLabel.backgroundColor = UIColor.red.withAlphaComponent(0.4)
    statusLabel.textAlignment = .center
    statusLabel.layer.cornerRadius = 10
    statusLabel.layer.masksToBounds = true
    statusLabel.sizeToFit()
    statusLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
    statusLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    statusLabel.leftInset = 10
    statusLabel.rightInset = 10
    statusLabel.translatesAutoresizingMaskIntoConstraints = false

    sceneView.addSubview(statusLabel)

    NSLayoutConstraint.activate([
      statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      statusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      statusLabel.heightAnchor.constraint(equalToConstant: 30),
    ])

    openSettingsLabel = UILabel()
    openSettingsLabel.font = UIFont.systemFont(ofSize: 18)
    openSettingsLabel.textColor = UIColor.white
    openSettingsLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    openSettingsLabel.text = "Press & Hold to Open Settings!"
    openSettingsLabel.textAlignment = .center  // Center the text
    openSettingsLabel.translatesAutoresizingMaskIntoConstraints = false
    openSettingsLabel.layer.cornerRadius = 10
    openSettingsLabel.layer.masksToBounds = true

    if UserDefaults.standard.bool(forKey: "hasOpenedSettings") == false {
      self.view.addSubview(openSettingsLabel)
      NSLayoutConstraint.activate([
        openSettingsLabel.topAnchor.constraint(equalTo: self.view.topAnchor),
        openSettingsLabel.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        openSettingsLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
        openSettingsLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
      ])
    }

    scheduler = CommandScheduler(scene: sceneView)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let configuration = ARWorldTrackingConfiguration()
    configuration.planeDetection = .horizontal
    sceneView.session.run(configuration)

    // TODO: Field picker
    guard let field = sceneView.loadModelFromResources("Field3d_2024") else {
      NSLog("Failed to load field model")
      return
    }
    sceneView.fieldNode = field
    sceneView.fieldNode.scale = SCNVector3(0.05, 0.05, 0.05)

    // Loads the saved robot and assigns a few properties from UserDefaults
    loadPrefs()

    sceneView.curContainerDummyNode?.isHidden = true

    // Handlers for taps, pinches, rotations, and long presses to manipulate the scene
    addGestureRecognizers()

    NTHandler = NetworkTablesHandler(
      robotNode: robotNode, statusLabel: statusLabel, sceneView: sceneView)

    // Attempts a connection with the saved connection info
    NTHandler.connect()

    scheduler.subscribeToCommandScheduler(
      client: NTHandler.client, key: "/SmartDashboard/Scheduler")
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    sceneView.session.pause()
  }

  // This is done to make sure the ARSceneView is resized when the device is rotated
  override func viewWillTransition(
    to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
  ) {
    super.viewWillTransition(to: size, with: coordinator)

    sceneView.frame = CGRect(origin: .zero, size: size)
  }

  func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
    instructionLabel.isHidden = false
    switch camera.trackingState {
    case .notAvailable:
      instructionLabel.text = "Tracking not available"
    case .limited(ARCamera.TrackingState.Reason.initializing):
      instructionLabel.text = "Move phone to start"
    case .limited(ARCamera.TrackingState.Reason.excessiveMotion):
      instructionLabel.text = "Slow down movement"
    case .limited(ARCamera.TrackingState.Reason.insufficientFeatures):
      instructionLabel.text = "More light or texture needed"
    case .limited(ARCamera.TrackingState.Reason.relocalizing):
      instructionLabel.text = "Relocalizing"
    case .limited(_):
      instructionLabel.text = "Move phone to start"
    case .normal:
      instructionLabel.isHidden = true
    }
  }
}
