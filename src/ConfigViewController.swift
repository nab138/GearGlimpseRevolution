import ARKit
import Foundation
import UIKit

enum CellType {
  case textField(
    placeholder: String, keyboardType: UIKeyboardType = .default,
    saveIn: String, defaultValue: String? = nil)
  case toggleSwitch(label: String, saveIn: String, defaultValue: Bool? = nil)
  case button(label: String, action: () -> Void)
  case robotConfig(robot: Robot)
  case customRobotConfig
  case importRobot
  case offsetField(label: String, defaultValue: String)
  case slider(label: String, min: Float, max: Float, saveIn: String, defaultValue: Float? = nil)
}

struct Row {
  var type: CellType
}

class ConfigViewController: UITableViewController, UIDocumentPickerDelegate {
  var NTHandler: NetworkTablesHandler!
  var fieldNode: SCNNode!
  var controller: RootViewController!
  var actions = [IndexPath: () -> Void]()

  var cellViews: [IndexPath: UIView] = [:]
  var sections: [[Row]] = []

  var selectedRobotName: String?

  var activityIndicator: UIActivityIndicatorView?

  var customRobot: Robot?
  var customRobotSelected = false

  override func viewDidLoad() {
    super.viewDidLoad()

    self.isModalInPresentation = true

    sections = [
      [
        Row(
          type: .textField(
            placeholder: "Team Number (for roboRIO)", keyboardType: .numberPad, saveIn: "teamNumber"
          )),
        Row(
          type: .textField(
            placeholder: "IP (for simulator)", keyboardType: .numbersAndPunctuation, saveIn: "ip")),
        Row(type: .textField(placeholder: "Port", keyboardType: .numberPad, saveIn: "port")),
        Row(type: .toggleSwitch(label: "Manual Address", saveIn: "manualAddress")),
      ],
      [
        Row(
          type: .button(
            label: "Set to full size", action: { self.fieldNode.scale = SCNVector3(1, 1, 1) })),
        Row(type: .toggleSwitch(label: "Visible", saveIn: "fieldVisible")),
        Row(type: .toggleSwitch(label: "Transparent", saveIn: "fieldTransparent")),
        Row(type: .toggleSwitch(label: "Detect AprilTags", saveIn: "detectAprilTags")),
        Row(type: .textField(placeholder: "Trajectory NT Key", saveIn: "trajectoryKey")),
        Row(type: .textField(placeholder: "Game Pieces NT Key", saveIn: "gamePiecesKey")),
      ],
      [
        Row(type: .textField(placeholder: "Robot NT Key", saveIn: "robotKey")),
        Row(type: .robotConfig(robot: Robot.kitBot)),
        Row(type: .robotConfig(robot: Robot.robot3044)),
        Row(type: .customRobotConfig),
      ],
      [
        Row(type: .importRobot),
        Row(
          type: .offsetField(
            label: "X Offset", defaultValue: UserDefaults.standard.string(forKey: "xOffset") ?? "0")
        ),
        Row(
          type: .offsetField(
            label: "Y Offset", defaultValue: UserDefaults.standard.string(forKey: "yOffset") ?? "0")
        ),
        Row(
          type: .offsetField(
            label: "Z Offset", defaultValue: UserDefaults.standard.string(forKey: "zOffset") ?? "0")
        ),
        Row(
          type: .offsetField(
            label: "X Rot", defaultValue: UserDefaults.standard.string(forKey: "xRot") ?? "0")),
        Row(
          type: .offsetField(
            label: "Y Rot", defaultValue: UserDefaults.standard.string(forKey: "yRot") ?? "0")),
        Row(
          type: .offsetField(
            label: "Z Rot", defaultValue: UserDefaults.standard.string(forKey: "zRot") ?? "0")),
      ],
      [
        Row(type: .toggleSwitch(label: "Scheduler Visible", saveIn: "schedulerVisible")),
        Row(type: .toggleSwitch(label: "FMS Visible", saveIn: "fmsVisible")),
        Row(type: .slider(label: "UI Height", min: 0, max: 10, saveIn: "schedulerHeight")),
        Row(type: .slider(label: "UI Size", min: 0.05, max: 1, saveIn: "schedulerSize")),
      ],
      [
        Row(
          type: .button(
            label: "Clear Saved Data",
            action: {
              let appDomain = Bundle.main.bundleIdentifier!
              UserDefaults.standard.removePersistentDomain(forName: appDomain)
              UserDefaults.standard.synchronize()
              exit(0)
            }))
      ],
    ]

    if let robotName = UserDefaults.standard.string(forKey: "selectedRobotName") {
      selectedRobotName = robotName
    } else {
      selectedRobotName = "2024 KitBot"
      UserDefaults.standard.set(selectedRobotName, forKey: "selectedRobotName")
    }

    loadCustomRobot()
    customRobotSelected = UserDefaults.standard.bool(forKey: "customRobotSelected")

    title = "Settings"
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .done, target: self, action: #selector(saveSettings))

    tableView = UITableView(frame: .zero, style: .insetGrouped)
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tapGesture.cancelsTouchesInView = false
    tableView.addGestureRecognizer(tapGesture)
  }

  func loadCustomRobot() {
    let robotName = UserDefaults.standard.string(forKey: "customRobotName") ?? "Custom Robot"
    if let bookmarkData = UserDefaults.standard.data(forKey: "customRobotBookmarkData") {
      var isStale = false
      do {
        let bookmarkURL = try URL(
          resolvingBookmarkData: bookmarkData, options: [], relativeTo: nil,
          bookmarkDataIsStale: &isStale)
        if isStale {
          // The bookmark data is stale, so you need to create a new bookmark
          let newBookmarkData = try bookmarkURL.bookmarkData(
            options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
          UserDefaults.standard.set(newBookmarkData, forKey: "customRobotBookmarkData")
        }
        loadCustomRobot(url: bookmarkURL, name: robotName)
      } catch {
        print("Failed to resolve bookmark: \(error)")
      }
    }
  }

  func loadCustomRobot(url: URL, name: String) {
    let offsetX = UserDefaults.standard.float(forKey: "xOffset")
    let offsetY = UserDefaults.standard.float(forKey: "yOffset")
    let offsetZ = UserDefaults.standard.float(forKey: "zOffset")
    let xRot = UserDefaults.standard.float(forKey: "xRot")
    let yRot = UserDefaults.standard.float(forKey: "yRot")
    let zRot = UserDefaults.standard.float(forKey: "zRot")
    let offsets = SCNVector3(offsetX, offsetY, offsetZ)
    let rotations = SCNVector3(xRot, yRot, zRot)
    customRobot = Robot(url: url, name: name, positionOffset: offsets, rotations: rotations)
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return sections.count
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return sections[section].count
  }

  @objc func textFieldDidChange(_ textField: UITextField) {
    if let indexPath = cellViews.first(where: { $0.value == textField })?.key {
      let row = sections[indexPath.section][indexPath.row]
      if case .textField(_, _, let saveIn, _) = row.type {
        UserDefaults.standard.set(textField.text, forKey: saveIn)
      }
    }
  }

  @objc func toggleDidChange(_ toggle: UISwitch) {
    if let indexPath = cellViews.first(where: { $0.value == toggle })?.key {
      let row = sections[indexPath.section][indexPath.row]
      if case .toggleSwitch(_, let saveIn, _) = row.type {
        UserDefaults.standard.set(toggle.isOn, forKey: saveIn)
      }
    }
  }

  @objc func sliderDidChange(_ slider: UISlider) {
    if let indexPath = cellViews.first(where: { $0.value == slider })?.key {
      let row = sections[indexPath.section][indexPath.row]
      if case .slider(_, _, _, let saveIn, _) = row.type {
        UserDefaults.standard.set(slider.value, forKey: saveIn)
      }
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
    -> UITableViewCell
  {
    let row = sections[indexPath.section][indexPath.row]
    let cell = UITableViewCell()
    switch row.type {
    case .textField(let placeholder, let keyboardType, let saveIn, let defaultValue):
      let textField = UITextField()
      textField.placeholder = placeholder
      textField.text = defaultValue ?? UserDefaults.standard.string(forKey: saveIn)
      textField.keyboardType = keyboardType
      textField.translatesAutoresizingMaskIntoConstraints = false
      cell.contentView.addSubview(textField)
      NSLayoutConstraint.activate([
        textField.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15),
        textField.trailingAnchor.constraint(
          equalTo: cell.contentView.trailingAnchor, constant: -15),
        textField.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
        textField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
      ])
      cellViews[indexPath] = textField
      textField.addTarget(
        self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    case .toggleSwitch(let label, let saveIn, let defaultValue):
      let toggleSwitch = UISwitch()
      toggleSwitch.isOn = defaultValue ?? UserDefaults.standard.bool(forKey: saveIn)
      toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
      cell.textLabel?.text = label
      cell.contentView.addSubview(toggleSwitch)
      NSLayoutConstraint.activate([
        toggleSwitch.trailingAnchor.constraint(
          equalTo: cell.contentView.trailingAnchor, constant: -15),
        toggleSwitch.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
      ])
      cellViews[indexPath] = toggleSwitch
      toggleSwitch.addTarget(
        self, action: #selector(toggleDidChange(_:)), for: .valueChanged)
    case .button(let label, let action):
      cell.textLabel?.text = label
      cell.textLabel?.textColor = view.tintColor
      cell.selectionStyle = .default
      cell.isUserInteractionEnabled = true
      let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.cellTapped(_:)))
      cell.addGestureRecognizer(tapGesture)
      actions[indexPath] = action
    case .robotConfig(let robot):
      cell.textLabel?.text = robot.name
      cell.selectionStyle = .default
      cell.isUserInteractionEnabled = true
      cell.accessoryType = (robot.name == selectedRobotName) ? .checkmark : .none
      let tapGesture = UITapGestureRecognizer(
        target: self, action: #selector(self.robotCellTapped(_:)))
      cell.addGestureRecognizer(tapGesture)
    case .customRobotConfig:
      cell.textLabel?.text = customRobot?.name ?? "Custom Robot"
      cell.selectionStyle = .default
      cell.isUserInteractionEnabled = customRobot != nil
      cell.accessoryType = (customRobot?.name == selectedRobotName) ? .checkmark : .none
      let tapGesture = UITapGestureRecognizer(
        target: self, action: #selector(self.robotCellTapped(_:)))
      cell.addGestureRecognizer(tapGesture)
    case .importRobot:
      cell.textLabel?.text = "Import Robot (.usdz)"
      cell.textLabel?.textColor = view.tintColor
      cell.selectionStyle = .default
      cell.isUserInteractionEnabled = true
      let tapGesture = UITapGestureRecognizer(
        target: self, action: #selector(self.importRobotTapped(_:)))
      cell.addGestureRecognizer(tapGesture)
    case .offsetField(let label, let defaultValue):
      let textField = UITextField()
      let labelView = UILabel()
      labelView.text = label
      labelView.translatesAutoresizingMaskIntoConstraints = false
      cell.contentView.addSubview(labelView)
      cell.contentView.addSubview(textField)
      textField.placeholder = "0"
      textField.text = defaultValue
      textField.keyboardType = .decimalPad
      let toolbar = UIToolbar()
      toolbar.sizeToFit()

      let width = UIScreen.main.bounds.width
      var frame = toolbar.frame
      frame.size.width = width
      toolbar.frame = frame

      let spaceBarButton = UIBarButtonItem(
        barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
      let plusMinusButton = UIBarButtonItem(
        title: "+/-", style: .done, target: self, action: #selector(self.plusMinusAction(_:)))
      plusMinusButton.tintColor = .label
      plusMinusButton.width = UIScreen.main.bounds.width / 3
      toolbar.items = [spaceBarButton, plusMinusButton]

      toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
      toolbar.backgroundColor = UIColor.clear

      let inputView = UIInputView(frame: toolbar.bounds, inputViewStyle: .keyboard)
      inputView.addSubview(toolbar)
      textField.inputAccessoryView = inputView

      textField.translatesAutoresizingMaskIntoConstraints = false
      cell.contentView.addSubview(textField)
      NSLayoutConstraint.activate([
        labelView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15),
        labelView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),

        textField.leadingAnchor.constraint(equalTo: labelView.trailingAnchor, constant: 15),
        textField.trailingAnchor.constraint(
          equalTo: cell.contentView.trailingAnchor, constant: -15),
        textField.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
        textField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
      ])
      cellViews[indexPath] = textField
    case .slider(let label, let min, let max, let saveIn, let defaultValue):
      let slider = UISlider()
      slider.minimumValue = min
      slider.maximumValue = max
      slider.value = defaultValue ?? UserDefaults.standard.float(forKey: saveIn)
      slider.translatesAutoresizingMaskIntoConstraints = false

      let dynamicLabel = UILabel()
      dynamicLabel.text = label
      dynamicLabel.sizeToFit()
      dynamicLabel.translatesAutoresizingMaskIntoConstraints = false

      cell.contentView.addSubview(dynamicLabel)
      cell.contentView.addSubview(slider)

      NSLayoutConstraint.activate([
        dynamicLabel.leadingAnchor.constraint(
          equalTo: cell.contentView.leadingAnchor, constant: 15),
        dynamicLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),

        slider.leadingAnchor.constraint(equalTo: dynamicLabel.trailingAnchor, constant: 15),
        slider.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -15),
        slider.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
      ])

      cellViews[indexPath] = slider
      slider.addTarget(
        self, action: #selector(sliderDidChange(_:)), for: .valueChanged)
    }
    return cell
  }

  @objc func plusMinusAction(_ sender: UIBarButtonItem) {
    guard let cell = cellViews.first(where: { $0.value.isFirstResponder }) else { return }
    guard let myField = cell.value as? UITextField else { return }
    guard let text = myField.text else { return }
    if text.hasPrefix("-") {
      myField.text = String(text.suffix(text.count - 1))
    } else {
      myField.text = "-\(text)"
    }
  }

  @objc func importRobotTapped(_ sender: UITapGestureRecognizer) {
    guard let usdzType = UTType(filenameExtension: "usdz") else { return }
    let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [usdzType])
    documentPicker.delegate = self
    present(documentPicker, animated: true, completion: nil)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL])
  {
    guard let url = urls.first else { return }
    let shouldStopAccessing = url.startAccessingSecurityScopedResource()

    loadCustomRobot(
      url: url, name: url.lastPathComponent.replacingOccurrences(of: ".usdz", with: ""))
    selectedRobotName = customRobot?.name
    customRobotSelected = true

    // Store the URL as a bookmark to persist access to the file across app launches
    do {
      let bookmarkData = try url.bookmarkData(
        options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
      UserDefaults.standard.set(bookmarkData, forKey: "customRobotBookmarkData")
    } catch {
      print("Failed to create bookmark: \(error)")
    }

    UserDefaults.standard.set(customRobot?.name, forKey: "customRobotName")

    if shouldStopAccessing {
      url.stopAccessingSecurityScopedResource()
    }

    tableView.reloadRows(
      at: [
        IndexPath(row: 1, section: 2),
        IndexPath(row: 2, section: 2),
        IndexPath(row: 3, section: 2),
      ], with: .none)
  }

  @objc func robotCellTapped(_ sender: UITapGestureRecognizer) {
    let cell = sender.view as! UITableViewCell
    if let indexPath = tableView.indexPath(for: cell) {
      let row = sections[indexPath.section][indexPath.row]
      if case .robotConfig(let robot) = row.type {
        selectedRobotName = robot.name
        customRobotSelected = false
      } else if case .customRobotConfig = row.type {
        selectedRobotName = customRobot?.name
        customRobotSelected = true
      }
      tableView.reloadRows(
        at: [
          IndexPath(row: 1, section: 2),
          IndexPath(row: 2, section: 2),
          IndexPath(row: 3, section: 2),
        ], with: .none)
    }
  }

  @objc func cellTapped(_ sender: UITapGestureRecognizer) {
    let cell = sender.view as! UITableViewCell
    if let indexPath = tableView.indexPath(for: cell), let action = actions[indexPath] {
      action()
    }
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
  {
    return 44.0
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
  {
    switch section {
    case 0:
      return "Connection"
    case 1:
      return "Field"
    case 2:
      return "Robot"
    case 3:
      return "Custom Robot Setup"
    case 4:
      return "UI"
    case 5:
      return "Developer Settings"
    default:
      return nil
    }
  }

  @objc func saveSettings() {
    let teamNumberTextField = cellViews[IndexPath(row: 0, section: 0)] as? UITextField
    let ipTextField = cellViews[IndexPath(row: 1, section: 0)] as? UITextField
    let portTextField = cellViews[IndexPath(row: 2, section: 0)] as? UITextField
    let manualAddressSwitch = cellViews[IndexPath(row: 3, section: 0)] as? UISwitch
    let robotKeyTextField = cellViews[IndexPath(row: 0, section: 2)] as? UITextField
    let trajectoryKeyTextField = cellViews[IndexPath(row: 4, section: 1)] as? UITextField
    let gamePiecesKeyTextField = cellViews[IndexPath(row: 5, section: 1)] as? UITextField

    if manualAddressSwitch?.isOn ?? false {
      NTHandler.ip = ipTextField?.text
    } else {
      NTHandler.ip = "roborio-" + (teamNumberTextField?.text ?? "") + "-frc.local"
    }

    let fieldVisibleSwitch = cellViews[IndexPath(row: 1, section: 1)] as? UISwitch
    let fieldTransparentSwitch = cellViews[IndexPath(row: 2, section: 1)] as? UISwitch
    let detectAprilTagsSwitch = cellViews[IndexPath(row: 3, section: 1)] as? UISwitch

    controller.shouldDetectAprilTags = detectAprilTagsSwitch?.isOn ?? false

    // Make field visible or invisible without affecting child nodes
    fieldNode.isHidden = !(fieldVisibleSwitch?.isOn ?? false)
    fieldNode.opacity = (fieldTransparentSwitch?.isOn ?? false) ? 0.5 : 1.0

    NTHandler.port = portTextField?.text
    NTHandler.robotKey = robotKeyTextField?.text
    NTHandler.trajectoryKey = trajectoryKeyTextField?.text
    NTHandler.gamePiecesKey = gamePiecesKeyTextField?.text

    let xOffsetTextField = cellViews[IndexPath(row: 1, section: 3)] as? UITextField
    let yOffsetTextField = cellViews[IndexPath(row: 2, section: 3)] as? UITextField
    let zOffsetTextField = cellViews[IndexPath(row: 3, section: 3)] as? UITextField

    let xRotTextField = cellViews[IndexPath(row: 4, section: 3)] as? UITextField
    let yRotTextField = cellViews[IndexPath(row: 5, section: 3)] as? UITextField
    let zRotTextField = cellViews[IndexPath(row: 6, section: 3)] as? UITextField

    let xOffsetCorrect = xOffsetTextField?.text != nil && Float((xOffsetTextField?.text)!) != nil
    let yOffsetCorrect = yOffsetTextField?.text != nil && Float((yOffsetTextField?.text)!) != nil
    let zOffsetCorrect = zOffsetTextField?.text != nil && Float((zOffsetTextField?.text)!) != nil
    let xOffset = Float(xOffsetTextField?.text ?? "0") ?? 0
    let yOffset = Float(yOffsetTextField?.text ?? "0") ?? 0
    let zOffset = Float(zOffsetTextField?.text ?? "0") ?? 0

    let offset = SCNVector3(xOffset, yOffset, zOffset)

    let xRotCorrect = xRotTextField?.text != nil && Float((xRotTextField?.text)!) != nil
    let yRotCorrect = yRotTextField?.text != nil && Float((yRotTextField?.text)!) != nil
    let zRotCorrect = zRotTextField?.text != nil && Float((zRotTextField?.text)!) != nil
    let xRot = Float(xRotTextField?.text ?? "0") ?? 0
    let yRot = Float(yRotTextField?.text ?? "0") ?? 0
    let zRot = Float(zRotTextField?.text ?? "0") ?? 0

    let rotations = SCNVector3(xRot, yRot, zRot)

    if customRobotSelected {
      if xOffsetCorrect && yOffsetCorrect && zOffsetCorrect {
        customRobot?.positionOffset = offset
      }
      if xRotCorrect && yRotCorrect && zRotCorrect {
        customRobot?.rotations = rotations
      }
    }

    let schedulerVisibleSwitch = cellViews[IndexPath(row: 0, section: 4)] as? UISwitch
    let fmsVisibleSwitch = cellViews[IndexPath(row: 1, section: 4)] as? UISwitch
    let uiHeightSlider = cellViews[IndexPath(row: 2, section: 4)] as? UISlider
    let uiSizeSlider = cellViews[IndexPath(row: 3, section: 4)] as? UISlider

    controller.floatingUI.height = uiHeightSlider?.value ?? 3
    controller.floatingUI.node.position.y =
      controller.sceneView.fieldNode.position.y
      + (controller.floatingUI.height * controller.sceneView.fieldNode.scale.y)

    let newSize = uiSizeSlider?.value ?? 0.25
    controller.floatingUI.scheduler.planeSize = newSize
    controller.floatingUI.scheduler.regenImage()

    controller.floatingUI.fms.planeSize = newSize
    controller.floatingUI.fms.regenImage()

    controller.floatingUI.scheduler.node.isHidden = !(schedulerVisibleSwitch?.isOn ?? true)
    controller.floatingUI.fms.node.isHidden = !(fmsVisibleSwitch?.isOn ?? true)

    controller.floatingUI.adjustPositionsBasedOnHidden()

    UserDefaults.standard.set(customRobotSelected, forKey: "customRobotSelected")

    if let selectedRobotName = selectedRobotName {
      if customRobotSelected {
        if selectedRobotName != UserDefaults.standard.string(forKey: "selectedRobotName")
          || (xOffsetCorrect && xOffset != UserDefaults.standard.float(forKey: "xOffset"))
          || (yOffsetCorrect && yOffset != UserDefaults.standard.float(forKey: "yOffset"))
          || (zOffsetCorrect && zOffset != UserDefaults.standard.float(forKey: "zOffset"))
          || (xRotCorrect && xRot != UserDefaults.standard.float(forKey: "xRot"))
          || (yRotCorrect && yRot != UserDefaults.standard.float(forKey: "yRot"))
          || (zRotCorrect && zRot != UserDefaults.standard.float(forKey: "zRot"))
        {
          UserDefaults.standard.set(selectedRobotName, forKey: "selectedRobotName")
          DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.controller.loadRobot(robot: self?.customRobot ?? Robot.kitBot)
          }
        }
      } else {
        if selectedRobotName != UserDefaults.standard.string(forKey: "selectedRobotName") {
          UserDefaults.standard.set(selectedRobotName, forKey: "selectedRobotName")
          DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.controller.loadRobot(name: selectedRobotName)
          }
        }
      }
    }

    if xOffsetCorrect { UserDefaults.standard.set(xOffset, forKey: "xOffset") }
    if yOffsetCorrect { UserDefaults.standard.set(yOffset, forKey: "yOffset") }
    if zOffsetCorrect { UserDefaults.standard.set(zOffset, forKey: "zOffset") }
    if xRotCorrect { UserDefaults.standard.set(xRot, forKey: "xRot") }
    if yRotCorrect { UserDefaults.standard.set(yRot, forKey: "yRot") }
    if zRotCorrect { UserDefaults.standard.set(zRot, forKey: "zRot") }

    UserDefaults.standard.synchronize()

    NTHandler.connect()

    dismiss(animated: true, completion: nil)
  }

  @objc func dismissKeyboard() {
    view.endEditing(true)
  }

  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String?
  {
    switch section {
    case 0:
      return "Use manual address for the simulator."
    case 1:
      return "Tap on a flat, horizontal surface to place the field."
    case 2:
      return
        "When importing a custom robot for the first time, you may need to restart the app for it to appear."
    case 3:
      return
        "You can convert your model to .usdz online. Only one robot can be imported at a time; subsequent imports will overwrite. Offsets can be changed after import."
    case 4:
      return
        "To publish the scheduler from robot code, add SmartDashboard.putData(CommandScheduler.getInstance()); to robotPeriodic."
    default:
      return nil
    }
  }
}
