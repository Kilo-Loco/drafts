//
//  DataSeeder.swift
//  room-booking
//
//  Created by Kilo Loco on 12/7/20.
//

import Amplify
import SwiftUI

class DataSeeder {
    static func seedRooms() {
        let seededRooms: [Room] = [
            Room(
                description: "One king size bed",
                city: "Los Angeles",
                price: 100,
                imageKey: "stockphoto-1"
            ),
            Room(
                description: "Two full sized beds",
                city: "Pasadena",
                price: 64,
                imageKey: "stockphoto-2"
            ),
            Room(
                description: "Whole studio apartment",
                city: "El Segundo",
                price: 120,
                imageKey: "stockphoto-3"
            ),
        ]
        
        seededRooms.forEach { room in
            Amplify.DataStore.save(room) { print("seeded", $0) }
        }
    }
}
