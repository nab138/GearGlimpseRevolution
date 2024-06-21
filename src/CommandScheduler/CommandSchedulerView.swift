import ARKit
import UIKit

class CommandSchedulerView: UIView {
  let mainLabel = UILabel()

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
    frame = CGRect(x: 10, y: 10, width: 400, height: 100)
    backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    visualEffectView.frame = bounds
    visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(visualEffectView)

    mainLabel.text = "Command Scheduler ⋅ No Data"
    mainLabel.font = UIFont.systemFont(ofSize: 20)
    mainLabel.translatesAutoresizingMaskIntoConstraints = false
    mainLabel.textAlignment = .left
    mainLabel.textColor = UIColor.label
    mainLabel.frame = CGRect(
      x: 10, y: 10, width: frame.width - 20, height: frame.height - 20)
    addSubview(mainLabel)
    mainLabel.sizeToFit()
  }

  func asImage() -> UIImage {
    UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
    layer.render(in: UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
  }

  func updateLabel(with text: String) {
    mainLabel.text = text
    mainLabel.sizeToFit()
  }
}
