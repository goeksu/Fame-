import SwiftUI

@main
struct FaceNameMemorizerApp: App {
    let persistenceController = PersistenceController.shared
    @State private var showingSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showingSplash {
                    SplashView()
                } else {
                    MenuView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                }
            }
            .onAppear {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        showingSplash = false
                    }
                }
            }
        }
    }
}
