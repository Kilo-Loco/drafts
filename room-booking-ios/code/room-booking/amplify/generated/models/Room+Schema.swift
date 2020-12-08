// swiftlint:disable all
import Amplify
import Foundation

extension Room {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case description
    case city
    case price
    case imageKey
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let room = Room.keys
    
    model.pluralName = "Rooms"
    
    model.fields(
      .id(),
      .field(room.description, is: .required, ofType: .string),
      .field(room.city, is: .required, ofType: .string),
      .field(room.price, is: .required, ofType: .int),
      .field(room.imageKey, is: .required, ofType: .string)
    )
    }
}