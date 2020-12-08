//
//  room_bookingApp.swift
//  room-booking
//
//  Created by Kilo Loco on 12/7/20.
//

import Amplify
import AmplifyPlugins
import SwiftUI

@main
struct room_bookingApp: App {
    
    @ObservedObject var sessionManager = SessionManager()
    
    init() {
        configureAmplify()
        seedRoomsIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            
            if sessionManager.currentUser != nil {
                TabView {
                    RoomsView()
                        .tabItem { Image(systemName: "list.bullet.below.rectangle") }
                    
                    MyBookingsView()
                        .tabItem { Image(systemName: "calendar") }
                }
                .environmentObject(sessionManager)
                
            } else {
                LoginView { user in
                    sessionManager.currentUser = user
                }
            }
        }
    }
    
    func configureAmplify() {
        let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels())
        let apiPlugin = AWSAPIPlugin(modelRegistration: AmplifyModels())

        do {
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.add(plugin: apiPlugin)
            try Amplify.configure()
            print("Initialized Amplify")
        } catch {
            print("Could not initialize Amplify: \(error)")
        }
    }
    
    func seedRoomsIfNeeded() {
        Amplify.DataStore.query(Room.self) { result in
            guard (try? result.get().isEmpty) == true else { return }
            DataSeeder.seedRooms()
        }
    }
}
