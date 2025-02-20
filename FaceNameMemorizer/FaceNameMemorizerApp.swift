//
//  FaceNameMemorizerApp.swift
//  FaceNameMemorizer
//
//  Created by Ahmet Göksu on 20.02.2025.
//

import SwiftUI

@main
struct FaceNameMemorizerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
