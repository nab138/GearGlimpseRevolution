import ARKit

enum RobotMode: String {
  case teleop = "Tele-Op Mode"
  case autonomous = "Autonomous Mode"
  case test = "Test Mode"
}

enum ControlMode: String {
  case enabled = "Robot Enabled"
  case disabled = "Robot Disabled"
}

enum EStop: String {
  case stopped = "Emergency Stopped"
  case normal = "Not E-Stopped"
}

enum Alliance: String {
  case red = "Red Alliance"
  case blue = "Blue Alliance"
}

enum Station: String {
  case one = "Station 1"
  case two = "Station 2"
  case three = "Station 3"
}

class FMS {
  var fmsSubID: Int?
  var allianceSubID: Int?
  var stationSubID: Int?

  let view = FMSView()
  var node: SCNNode!
  var plane: SCNPlane!
  var arScene: ARSceneView!

  var planeSize: Float = 0.25

  private var updateTimer: Timer?

  /*
    Field	Mask	    Comment
    E-Stop	x.......	0: Normal, 1: Emergency Stopped
    Enabled	.....x..	0: Disabled, 1: Enabled
    Mode	......xx	0: TeleOp, 1: Test, 2: Autonomous
  */
  let estopMask: Int8 = 0b0001000
  let enabledMask: Int8 = 0b000001
  let modeMask: Int8 = 0b0000110

  var mode: RobotMode?
  var control: ControlMode?
  var estopStatus: EStop?
  var alliance: Alliance?
  var station: Station?

  var displayedStation: Station?
  var displayedAlliance: Alliance?

  init(scene: ARSceneView) {
    arScene = scene
    loadViewNode()
  }

  private func loadViewNode() {
    plane = SCNPlane(width: CGFloat(planeSize / 2), height: CGFloat(planeSize / 2))
    plane.firstMaterial?.isDoubleSided = true

    node = SCNNode(geometry: plane)
    regenImage()

    let billboardConstraint = SCNBillboardConstraint()
    billboardConstraint.freeAxes = [.Y, .X]
    node.constraints = [billboardConstraint]

    node.isHidden = !UserDefaults.standard.bool(forKey: "fmsVisible")
  }

  func regenImage() {
    let image = view.asImage()
    let aspectRatio = image.size.width / image.size.height
    plane.width = CGFloat(planeSize / 2)
    plane.height = CGFloat(planeSize / 2) / aspectRatio
    plane.firstMaterial?.diffuse.contents = image

    node.geometry = plane
  }

  func subscribeToFMS(client: NT4Client) {
    if fmsSubID != nil {
      client.unsubscribe(subID: fmsSubID!)
    }
    fmsSubID = client.subscribe(
      key: "/FMSInfo/FMSControlData",
      callback: { topic, timestamp, data in
        if let fmsControl = data as? Int8 {
          if fmsControl == 0 {
            self.estopStatus = nil
            self.control = nil
            self.mode = nil
            self.updateView()
            return
          }

          let estop = fmsControl & self.estopMask
          let enabled = fmsControl & self.enabledMask
          let mode = fmsControl & self.modeMask

          if estop == 0 {
            self.estopStatus = .normal
          } else {
            self.estopStatus = .stopped
          }

          if enabled == 0 {
            self.control = .disabled
          } else {
            self.control = .enabled
          }

          switch mode {
          case 0:
            self.mode = .teleop
          case 4:
            self.mode = .test
          case 2:
            self.mode = .autonomous
          default:
            self.mode = nil
          }
          self.updateView()
        }
      }, periodic: 0.1, all: true)
    if allianceSubID != nil {
      client.unsubscribe(subID: allianceSubID!)
    }
    allianceSubID = client.subscribe(
      key: "/FMSInfo/IsRedAlliance",
      callback: { topic, timestamp, data in
        if let fmsControl = data as? Bool {
          if fmsControl {
            self.alliance = .red
          } else {
            self.alliance = .blue
          }
        }
      }, periodic: 0.1, all: true)

    if stationSubID != nil {
      client.unsubscribe(subID: stationSubID!)
    }
    stationSubID = client.subscribe(
      key: "/FMSInfo/StationNumber",
      callback: { topic, timestamp, data in
        if let fmsControl = data as? Int8 {
          switch fmsControl {
          case 1:
            self.station = .one
          case 2:
            self.station = .two
          case 3:
            self.station = .three
          default:
            self.station = nil
          }
          
        }
      }, periodic: 0.09, all: true)

    checkForStationAllianceUpdates()
  }

  private func checkForStationAllianceUpdates() {
    if updateTimer != nil {
      updateTimer?.invalidate()
    }
    updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      if self.displayedAlliance != self.alliance || self.displayedStation != self.station {
        self.displayedAlliance = self.alliance
        self.displayedStation = self.station
        self.updateView()
      }
    }
  }

  private func updateView() {
    view.modeLabel.text = mode?.rawValue ?? "Mode: No Data"
    view.modeLabel.sizeToFit()
    view.enabledLabel.text = control?.rawValue ?? "Enabled: No Data"
    view.enabledLabel.sizeToFit()
    view.estopLabel.text = estopStatus?.rawValue ?? "E-Stop: No Data"
    view.estopLabel.sizeToFit()
    view.allianceLabel.text = displayedAlliance?.rawValue ?? "Alliance: No Data"
    view.allianceLabel.sizeToFit()
    view.stationLabel.text = displayedStation?.rawValue ?? "Station: No Data"
    view.stationLabel.sizeToFit()

    regenImage()
  }
}
