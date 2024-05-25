import UIKit
import Foundation
import ARKit

enum CellType {
    case textField(placeholder: String, defaultValue: String?, keyboardType: UIKeyboardType = .default)
    case toggleSwitch(label: String, defaultValue: Bool = false)
    case button(label: String, action: () -> Void)
}

struct Row {
    var type: CellType
}


class ConfigViewController: UITableViewController {
    var ipTextField: UITextField!
    var portTextField: UITextField!
    var robotKeyTextField: UITextField!
    var NTHandler: NetworkTablesHandler!
    var fieldNode: SCNNode!
    var actions = [IndexPath: () -> Void]()

    var cellViews: [IndexPath: UIView] = [:]
        var sections: [[Row]] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        sections = [
            [
                Row(type: .textField(placeholder: "Team Number", defaultValue: UserDefaults.standard.string(forKey: "teamNumber"), keyboardType: .numberPad)),
                Row(type: .textField(placeholder: "IP Address", defaultValue: UserDefaults.standard.string(forKey: "ip"), keyboardType: .numbersAndPunctuation)),
                Row(type: .textField(placeholder: "Port", defaultValue: UserDefaults.standard.string(forKey: "port"), keyboardType: .numberPad)),
                Row(type: .toggleSwitch(label: "Use Manual Address", defaultValue: UserDefaults.standard.bool(forKey: "manualAddress")))
            ],
            [
                Row(type: .textField(placeholder: "Robot Key", defaultValue: UserDefaults.standard.string(forKey: "robotKey"))),
            ],
            [
                Row(type: .button(label: "Set Full-Size Field", action: {
                    self.fieldNode.scale = SCNVector3(1, 1, 1)
                })),
            ],
            [
                Row(type: .button(label: "Clear Saved Data", action: {
                    let appDomain = Bundle.main.bundleIdentifier!
                    UserDefaults.standard.removePersistentDomain(forName: appDomain)
                })),
            ]
        ]

        title = "Settings"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveSettings))

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section][indexPath.row]
        let cell = UITableViewCell()
        switch row.type {
        case .textField(let placeholder, let defaultValue, let keyboardType):
            let textField = UITextField()
            textField.placeholder = placeholder
            textField.text = defaultValue
            textField.keyboardType = keyboardType
            textField.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(textField)
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15),
                textField.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -15),
                textField.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                textField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
            ])
            cellViews[indexPath] = textField
        case .toggleSwitch(let label, let defaultValue):
            let toggleSwitch = UISwitch()
            toggleSwitch.isOn = defaultValue
            toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
            cell.textLabel?.text = label
            cell.contentView.addSubview(toggleSwitch)
            NSLayoutConstraint.activate([
                toggleSwitch.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -15),
                toggleSwitch.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
            ])
            cellViews[indexPath] = toggleSwitch
        case .button(let label, let action):
            cell.textLabel?.text = label
            cell.textLabel?.textColor = view.tintColor
            cell.selectionStyle = .default
            cell.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.cellTapped(_:)))
            cell.addGestureRecognizer(tapGesture)
            actions[indexPath] = action
        }
        return cell
    }

    @objc func cellTapped(_ sender: UITapGestureRecognizer) {
        let cell = sender.view as! UITableViewCell
        if let indexPath = tableView.indexPath(for: cell), let action = actions[indexPath] {
            action()
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Connection Settings"
        case 1:
            return "Robot Settings"
        case 2:
            return "AR Settings"
        case 3:
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
        let robotKeyTextField = cellViews[IndexPath(row: 0, section: 1)] as? UITextField
        
        if manualAddressSwitch?.isOn ?? false {
            NTHandler.ip = ipTextField?.text
        } else {
            NTHandler.ip = "roborio-" + (teamNumberTextField?.text ?? "") + "-frc.local"
        }

        NTHandler.port = portTextField?.text
        NTHandler.robotKey = robotKeyTextField?.text

        UserDefaults.standard.set(teamNumberTextField?.text, forKey: "teamNumber")
        UserDefaults.standard.set(ipTextField?.text, forKey: "ip")
        UserDefaults.standard.set(portTextField?.text, forKey: "port")
        UserDefaults.standard.set(robotKeyTextField?.text, forKey: "robotKey")
        UserDefaults.standard.set(manualAddressSwitch?.isOn, forKey: "manualAddress")
        UserDefaults.standard.synchronize()

        NTHandler.connect()

        dismiss(animated: true, completion: nil)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}