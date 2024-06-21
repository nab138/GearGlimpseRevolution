import ARKit
import UIKit

class CommandSchedulerView: UIView {
  let mainLabel = UILabel()
  let secondLabel = UILabel()
  private let padding: CGFloat = 10

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupView()
  }

  private func setupView() {
    layer.cornerRadius = 10
    clipsToBounds = true
    frame = CGRect(x: padding, y: padding, width: 325, height: 200)
    backgroundColor = UIColor.systemBackground.withAlphaComponent(0.85)
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    visualEffectView.frame = bounds
    visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(visualEffectView)

    mainLabel.text = "Command Scheduler"
    mainLabel.font = UIFont.systemFont(ofSize: 20)
    mainLabel.translatesAutoresizingMaskIntoConstraints = false
    mainLabel.textAlignment = .left
    mainLabel.textColor = UIColor.label
    mainLabel.frame = CGRect(
      x: padding, y: padding, width: frame.width - (2 * padding),
      height: frame.height - (2 * padding))
    addSubview(mainLabel)
    mainLabel.sizeToFit()

    secondLabel.text = "No Data"
    secondLabel.font = UIFont.systemFont(ofSize: 16)
    secondLabel.translatesAutoresizingMaskIntoConstraints = false
    secondLabel.textAlignment = .left
    secondLabel.textColor = UIColor.label
    secondLabel.frame = CGRect(
      x: padding, y: padding + mainLabel.frame.height, width: frame.width - (2 * padding),
      height: frame.height - (2 * padding))
    addSubview(secondLabel)
    secondLabel.sizeToFit()

    frame.size.height = secondLabel.frame.maxY + (2 * padding)
  }

  func asImage() -> UIImage {
    UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
    layer.render(in: UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
  }

  func updateLabel(with text: String) {
    secondLabel.text = text
    secondLabel.sizeToFit()
  }

  func setCommands(_ commands: [String]) {
    // Remove existing command labels
    subviews.forEach { view in
      if view is UILabel && view != mainLabel && view != secondLabel {
        view.removeFromSuperview()
      }
    }

    var yOffset: CGFloat = secondLabel.frame.maxY + padding
    for command in commands {
      let commandLabel = PaddedLabel()
      commandLabel.text = command
      commandLabel.font = UIFont.systemFont(ofSize: 16)
      commandLabel.translatesAutoresizingMaskIntoConstraints = true
      commandLabel.textAlignment = .left
      commandLabel.textColor = UIColor.label
      commandLabel.layer.cornerRadius = 10
      commandLabel.layer.masksToBounds = true
      commandLabel.backgroundColor = UIColor.systemGray.withAlphaComponent(0.5)
      commandLabel.leftInset = padding
      commandLabel.frame = CGRect(
        x: padding, y: yOffset, width: frame.width - (2 * padding), height: 20 + (2 * padding))
      addSubview(commandLabel)
      yOffset += commandLabel.frame.height + padding
    }

    frame.size.height = yOffset + padding
  }
}
