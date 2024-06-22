import UIKit

class FMSView: UIView {
  let mainLabel = UILabel()
  let enabledLabel = UILabel()
  let estopLabel = UILabel()
  let modeLabel = UILabel()
  let allianceLabel = UILabel()
  let stationLabel = UILabel()

  let padding: CGFloat = 10

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
    frame = CGRect(x: padding, y: padding, width: 150, height: 200)
    backgroundColor = UIColor.systemBackground.withAlphaComponent(0.85)
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    visualEffectView.frame = bounds
    visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(visualEffectView)

    mainLabel.text = "FMS Info"
    mainLabel.font = UIFont.systemFont(ofSize: 18)
    mainLabel.translatesAutoresizingMaskIntoConstraints = false
    mainLabel.textAlignment = .left
    mainLabel.textColor = UIColor.label
    mainLabel.frame = CGRect(x: padding, y: padding, width: frame.width - (2 * padding), height: 0)
    addSubview(mainLabel)
    mainLabel.sizeToFit()

    enabledLabel.text = "Enabled: No Data"
    enabledLabel.font = UIFont.systemFont(ofSize: 12)
    enabledLabel.translatesAutoresizingMaskIntoConstraints = false
    enabledLabel.textAlignment = .left
    enabledLabel.textColor = UIColor.secondaryLabel.withAlphaComponent(0.8)
    enabledLabel.frame = CGRect(
      x: padding, y: mainLabel.frame.maxY + padding, width: frame.width - (2 * padding), height: 0)
    addSubview(enabledLabel)
    enabledLabel.sizeToFit()

    estopLabel.text = "E-Stop: No Data"
    estopLabel.font = UIFont.systemFont(ofSize: 12)
    estopLabel.translatesAutoresizingMaskIntoConstraints = false
    estopLabel.textAlignment = .left
    estopLabel.textColor = UIColor.secondaryLabel.withAlphaComponent(0.8)
    estopLabel.frame = CGRect(
      x: padding, y: enabledLabel.frame.maxY + (padding / 2), width: frame.width - (2 * padding),
      height: 0)
    addSubview(estopLabel)
    estopLabel.sizeToFit()

    modeLabel.text = "Mode: No Data"
    modeLabel.font = UIFont.systemFont(ofSize: 12)
    modeLabel.translatesAutoresizingMaskIntoConstraints = false
    modeLabel.textAlignment = .left
    modeLabel.textColor = UIColor.secondaryLabel.withAlphaComponent(0.8)
    modeLabel.frame = CGRect(
      x: padding, y: estopLabel.frame.maxY + (padding / 2), width: frame.width - (2 * padding),
      height: 0)
    addSubview(modeLabel)
    modeLabel.sizeToFit()

    allianceLabel.text = "Alliance: No Data"
    allianceLabel.font = UIFont.systemFont(ofSize: 12)
    allianceLabel.translatesAutoresizingMaskIntoConstraints = false
    allianceLabel.textAlignment = .left
    allianceLabel.textColor = UIColor.secondaryLabel.withAlphaComponent(0.8)
    allianceLabel.frame = CGRect(
      x: padding, y: modeLabel.frame.maxY + (padding / 2), width: frame.width - (2 * padding),
      height: 0)
    addSubview(allianceLabel)
    allianceLabel.sizeToFit()

    stationLabel.text = "Station: No Data"
    stationLabel.font = UIFont.systemFont(ofSize: 12)
    stationLabel.translatesAutoresizingMaskIntoConstraints = false
    stationLabel.textAlignment = .left
    stationLabel.textColor = UIColor.secondaryLabel.withAlphaComponent(0.8)
    stationLabel.frame = CGRect(
      x: padding, y: allianceLabel.frame.maxY + (padding / 2), width: frame.width - (2 * padding),
      height: 0)
    addSubview(stationLabel)
    stationLabel.sizeToFit()

    frame.size.height = stationLabel.frame.maxY + padding
  }

  func asImage() -> UIImage {
    UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
    layer.render(in: UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
  }
}
