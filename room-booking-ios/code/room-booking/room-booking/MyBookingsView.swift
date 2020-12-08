//
//  MyBookingsView.swift
//  room-booking
//
//  Created by Kilo Loco on 12/7/20.
//

import Amplify
import SwiftUI

struct MyBookingsView: View {
    
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject var viewModel = ViewModel()
    
    var currentUser: User? {
        sessionManager.currentUser
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.bookings) { booking in
                        RoomListingView(
                            room: booking.room,
                            bookingDates: booking.bookingDates
                        )
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("My Bookings")
        }
        .onAppear {
            guard let currentUser = self.currentUser else { return }
            viewModel.getBookings(for: currentUser)
        }
    }
}

extension MyBookingsView {
    class ViewModel: ObservableObject {
        @Published var bookings = [Booking]()
        
        func getBookings(for user: User) {
            let booking = Booking.keys
            
            Amplify.DataStore.query(
                Booking.self,
                where: booking.guestId == user.id,
                sort: .descending(booking.checkInDate)
            ) { result in
                do {
                    let bookings = try result.get()
                    print("bookings", bookings)
                    DispatchQueue.main.async { [weak self] in
                        self?.bookings = bookings
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
}

struct MyHotels_Previews: PreviewProvider {
    static var previews: some View {
        MyBookingsView()
    }
}
