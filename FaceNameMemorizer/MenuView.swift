import SwiftUI

struct MenuView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                Image(systemName: "person.crop.rectangle.stack.fill") // Example SF Symbol
                    .font(.system(size: 60)) // Larger icon
                    .foregroundColor(.accentColor) // Use the system accent color
                    .padding(.bottom, 20) // Add some padding

                Text("Face & Name Memorizer")
                    .font(.largeTitle)
                    .fontWeight(.semibold) // Slightly less bold

                Spacer() // Flexible space

                NavigationLink(destination: GameView()) {
                    Label("Start Game", systemImage: "play.fill") // Use a Label with an icon
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor) // Use accent color
                        .foregroundColor(.white)
                        .cornerRadius(12) // Slightly larger corner radius
                }

                NavigationLink(destination: FaceGalleryView()) {
                    Label("Face Gallery", systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2)) // Subtle background
                        .foregroundColor(.primary) // Use primary text color
                        .cornerRadius(12)
                }

                Spacer() // Push content towards the center
            }
            .padding(.horizontal, 40) // Consistent horizontal padding
            .navigationTitle("Fame!") // Standard navigation bar title
            .navigationBarTitleDisplayMode(.inline) // Inline title display
        }
    }
}
