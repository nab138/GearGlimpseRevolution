import Foundation

struct TagData: Codable {
  let tags: [Tag]
  let field: Field
}

struct Tag: Codable {
  let ID: Int
  let pose: Pose
}

struct Pose: Codable {
  let translation: Translation
  let rotation: Rotation
}

struct Translation: Codable {
  let x, y, z: Double
}

struct Rotation: Codable {
  let quaternion: Quaternion
}

struct Quaternion: Codable {
  let W, X, Y, Z: Double
}

struct Field: Codable {
  let length, width: Double
}

class AprilTagParser {
  var tagData: TagData?

  func parseTagData(from jsonData: Data) -> TagData? {
    let decoder = JSONDecoder()
    do {
      let tagData = try decoder.decode(TagData.self, from: jsonData)
      return tagData
    } catch {
      print("Error decoding JSON: \(error)")
      return nil
    }
  }

  func getAprilTagData() -> TagData? {
    if tagData != nil {
      return tagData
    }
    if let url = Bundle.main.url(forResource: "2024-crescendo", withExtension: "json"),
      let jsonData = try? Data(contentsOf: url)
    {
      tagData = parseTagData(from: jsonData)
      return tagData
    }
    return nil
  }

  func getDataForTag(_ tagID: Int) -> Tag? {
    return getAprilTagData()?.tags.first { $0.ID == tagID }
  }
}
