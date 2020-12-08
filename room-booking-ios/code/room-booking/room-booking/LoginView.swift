//
//  LoginView.swift
//  room-booking
//
//  Created by Kilo Loco on 12/7/20.
//

import Amplify
import SwiftUI

struct LoginView: View {
    
    @StateObject var viewModel = ViewModel()
    
    let onLogin: (User) -> Void
    
    var body: some View {
        VStack {
            TextField("Username", text: $viewModel.username)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
                .padding(.horizontal, 40)
            
            Button("Login") {
                viewModel.login(completion: onLogin)
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.purple)
            .clipShape(Capsule())
        }
    }
}

extension LoginView {
    class ViewModel: ObservableObject {
        @Published var username = String()
        
        func login(completion: @escaping (User) -> Void) {
            Amplify.DataStore.query(User.self, byId: username) { result in
                if let queriedUser = try? result.get() {
                    print("queried user", queriedUser)
                    completion(queriedUser)

                } else {
                    let newUser = User(id: username, username: username)
                    Amplify.DataStore.save(newUser) { result in

                        do {
                            let savedUser = try result.get()
                            print("saved user", savedUser)
                            completion(savedUser)

                        } catch {
                            print(error)
                            fatalError()
                        }
                    }
                }

            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(onLogin: {_ in})
    }
}
