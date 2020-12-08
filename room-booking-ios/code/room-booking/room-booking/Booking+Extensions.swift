//
//  Booking+Extensions.swift
//  room-booking
//
//  Created by Kilo Loco on 12/7/20.
//

import Foundation

extension Booking: Identifiable {}

extension Booking {
    var bookingDates: (checkInDate: Date, checkOutDate: Date) {
        (checkInDate.foundationDate, checkOutDate.foundationDate)
    }
}
