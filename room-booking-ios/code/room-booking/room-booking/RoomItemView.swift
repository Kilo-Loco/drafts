//
//  RoomItemView.swift
//  room-booking
//
//  Created by Kilo Loco on 12/7/20.
//

import SwiftUI

struct RoomItemView: View {
    
    let room: Room
    let bookingDates: (checkInDate: Date, checkOutDate: Date)?
    
    var bookingDescription: String? {
        guard let bookingDates = self.bookingDates else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        
        let checkIn = formatter.string(from: bookingDates.checkInDate)
        let checkOut = formatter.string(from: bookingDates.checkOutDate)
        
        return "Booked from \(checkIn) to \(checkOut)"
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Image(room.imageKey)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: .infinity, height: 250)
                .background(Color.gray)
                .cornerRadius(10)
                
            Text("\(room.description) - \(room.city)")
                .font(.title3)
            
            if let bookingDescription = self.bookingDescription {
                Text(bookingDescription)
            } else {
                Text("$\(room.price)").bold()
                    + Text(" / night")
            }
            
        }
    }
}

struct RoomItemView_Previews: PreviewProvider {
    static var previews: some View {
        RoomItemView(room: Room(description: "One King Size Bed", city: "Los Angeles", price: 25, imageKey: "stockphoto-3"), bookingDates: nil)
    }
}
