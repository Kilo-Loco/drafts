// swiftlint:disable all
import Amplify
import Foundation

extension Booking {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case room
    case guestId
    case checkInDate
    case checkOutDate
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let booking = Booking.keys
    
    model.pluralName = "Bookings"
    
    model.fields(
      .id(),
      .belongsTo(booking.room, is: .required, ofType: Room.self, targetName: "bookingRoomId"),
      .field(booking.guestId, is: .required, ofType: .string),
      .field(booking.checkInDate, is: .required, ofType: .date),
      .field(booking.checkOutDate, is: .required, ofType: .date)
    )
    }
}