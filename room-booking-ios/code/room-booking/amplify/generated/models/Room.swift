// swiftlint:disable all
import Amplify
import Foundation

public struct Room: Model {
  public let id: String
  public var description: String
  public var city: String
  public var price: Int
  public var imageKey: String
  
  public init(id: String = UUID().uuidString,
      description: String,
      city: String,
      price: Int,
      imageKey: String) {
      self.id = id
      self.description = description
      self.city = city
      self.price = price
      self.imageKey = imageKey
  }
}