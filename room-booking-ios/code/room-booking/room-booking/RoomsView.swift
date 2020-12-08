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
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.rooms) { room in
                        NavigationLink(
                            destination: RoomDetailsView(room: room),
                            label: { RoomListingView(room: room, bookingDates: nil) }
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
        RoomsView()
    }
}
