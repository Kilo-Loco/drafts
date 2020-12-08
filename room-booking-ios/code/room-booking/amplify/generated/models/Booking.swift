// swiftlint:disable all
import Amplify
import Foundation

public struct Booking: Model {
  public let id: String
  public var room: Room
  public var guestId: String
  public var checkInDate: Temporal.Date
  public var checkOutDate: Temporal.Date
  
  public init(id: String = UUID().uuidString,
      room: Room,
      guestId: String,
      checkInDate: Temporal.Date,
      checkOutDate: Temporal.Date) {
      self.id = id
      self.room = room
      self.guestId = guestId
      self.checkInDate = checkInDate
      self.checkOutDate = checkOutDate
  }
}