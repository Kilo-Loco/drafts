//
//  RoomDetailsView.swift
//  room-booking
//
//  Created by Kilo Loco on 12/7/20.
//

import Amplify
import SwiftUI

struct RoomDetailsView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject var viewModel = ViewModel()
    
    let room: Room
    
    var currentUser: User? {
        sessionManager.currentUser
    }
    
    var body: some View {
        VStack {
            Image(room.imageKey)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 250)
                
            VStack(alignment: .leading) {
            
                Text(room.description)
                    .font(.title)
                
                Text(room.city)
                    .font(.title3)
                
                Spacer()
                
                DatePicker("Check In", selection: $viewModel.checkInDate, displayedComponents: .date)
                
                DatePicker("Check Out", selection: $viewModel.checkOutDate, displayedComponents: .date)
                
                Button("Book for $\(room.price)") {
                    guard let currentUser = self.currentUser else { return }
                    viewModel.book(room, for: currentUser)
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(Color.purple)
                .clipShape(Capsule())
                .padding(.vertical)
            }
            .padding()
        }
        .navigationBarTitle("Details", displayMode: .inline)
    }
}

extension RoomDetailsView {
    class ViewModel: ObservableObject {
        
        @Published var checkInDate: Date = Calendar.current.date(
            byAdding: .day,
            value: 15,
            to: Date()
        )!
        
        @Published var checkOutDate = Calendar.current.date(
            byAdding: .day,
            value: 18,
            to: Date()
        )!
        
        func book(_ room: Room, for user: User) {
            
            let booking = Booking(
                room: room,
                guestId: user.id,
                checkInDate: Temporal.Date(checkInDate),
                checkOutDate: Temporal.Date(checkOutDate)
            )
            
            Amplify.DataStore.save(booking) { result in
                do {
                    let savedBooking = try result.get()
                    print("booked", savedBooking)

                } catch {
                    print(error)
                }
            }
        }
    }
}

struct RoomDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        RoomDetailsView(room: Room(description: "King sized bed", city: "Los Angeles", price: 100, imageKey: "stockphoto-1"))
    }
}
