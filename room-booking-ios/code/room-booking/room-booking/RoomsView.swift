//
//  RoomsView.swift
//  room-booking
//
//  Created by Kilo Loco on 12/7/20.
//

import Amplify
import SwiftUI

struct RoomsView: View {
    
    @StateObject var viewModel = ViewModel()
    
    init(vm: ViewModel = .init()) {
        _viewModel = .init(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.rooms) { room in
                        NavigationLink(
                            destination: RoomDetailsView(room: room),
                            label: { RoomItemView(room: room, bookingDates: nil) }
                        )
                        .accentColor(Color(.label))
                        .padding()
                    }
                }
            }
            .navigationTitle("Rooms")
        }
        .onAppear(perform: viewModel.getRooms)
    }
}

extension RoomsView {
    class ViewModel: ObservableObject {
        @Published var rooms = [Room]()
        
        func getRooms() {
            Amplify.DataStore.query(Room.self) { result in
                do {
                    let rooms = try result.get()
                    print(rooms)
                    DispatchQueue.main.async { [weak self] in
                        self?.rooms = rooms
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
}

struct RoomsView_Previews: PreviewProvider {
    static var previews: some View {
        var vm = RoomsView.ViewModel()
        vm.rooms = [
            Room(description: "One king size bed", city: "Los Angeles", price: 100, imageKey: "stockphoto-1"),
            Room(description: "Studio apartment", city: "El Segundo", price: 120, imageKey: "stockphoto-3")
        ]
        return RoomsView(vm: vm)
    }
}
