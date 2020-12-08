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
    
    init(vm: ViewModel = .init()) {
        _viewModel = .init(wrappedValue: vm)
    }
    
    var currentUser: User? {
        sessionManager.currentUser
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.bookings) { booking in
                        RoomItemView(
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
                sort: .ascending(booking.checkInDate)
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
        let room = Room(description: "Studio apartment", city: "El Segundo", price: 120, imageKey: "stockphoto-3")
        let booking = Booking(room: room, guestId: "", checkInDate: .init(Calendar.current.date(byAdding: .day, value: 14, to: Date())!), checkOutDate: .init(Calendar.current.date(byAdding: .day, value: 16, to: Date())!))
        let vm = MyBookingsView.ViewModel()
        vm.bookings = [booking]
        return MyBookingsView(vm: vm)
            .environmentObject(SessionManager())
    }
}
