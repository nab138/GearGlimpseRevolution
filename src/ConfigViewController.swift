import UIKit
import Foundation

class ConfigViewController: UITableViewController {
    var ipTextField: UITextField!
    var portTextField: UITextField!
    var robotKeyTextField: UITextField!
    var NTHandler: NetworkTablesHandler!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Settings"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveSettings))

        tableView = UITableView(frame: .zero, style: .grouped)

        ipTextField = UITextField()
        ipTextField.placeholder = "IP Address"
        ipTextField.text = UserDefaults.standard.string(forKey: "ip")
        ipTextField.keyboardType = .numbersAndPunctuation

        portTextField = UITextField()
        portTextField.placeholder = "Port"
        portTextField.text = UserDefaults.standard.string(forKey: "port")
        portTextField.keyboardType = .numbersAndPunctuation

        robotKeyTextField = UITextField()
        robotKeyTextField.placeholder = "Robot Key"
        robotKeyTextField.text = UserDefaults.standard.string(forKey: "robotKey")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let textField: UITextField
        if indexPath.section == 0 {
            textField = indexPath.row == 0 ? ipTextField : portTextField
        } else {
            textField = robotKeyTextField
        }
        cell.contentView.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15),
            textField.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -15),
            textField.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            textField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        ])
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Network Tables" : "Robot"
    }

    @objc func saveSettings() {
        NTHandler.ip = ipTextField.text
        NTHandler.port = portTextField.text
        NTHandler.robotKey = robotKeyTextField.text
        NTHandler.connect()
        UserDefaults.standard.set(ipTextField.text, forKey: "ip")
        UserDefaults.standard.set(portTextField.text, forKey: "port")
        UserDefaults.standard.set(robotKeyTextField.text, forKey: "robotKey")

        dismiss(animated: true, completion: nil)
    }
}