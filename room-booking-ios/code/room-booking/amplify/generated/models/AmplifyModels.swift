// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "c95c0457f6bff29107fae5c7266896da"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Booking.self)
    ModelRegistry.register(modelType: Room.self)
    ModelRegistry.register(modelType: User.self)
  }
}