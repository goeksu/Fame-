import SwiftUI
import CoreData
// Import UIKit for haptics
import UIKit

struct GameView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Person.name, ascending: true)],
        animation: .default)
    private var people: FetchedResults<Person>

    @State private var currentPerson: Person?
    @State private var options: [String] = []
    @State private var score = 0
    @State private var gameOver = false
    @State private var showFeedback = false
    @State private var selectedName = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            if let person = currentPerson, let imageName = person.imageName {
                // Image Display
                if imageName.hasPrefix("uuid-") {
                    if let uiImage = loadImageFromDocumentsDirectory(imageName: imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 250)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.secondary, lineWidth: 1))
                    } else {
                        errorImageView()
                    }
                } else {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.secondary, lineWidth: 1))
                }

                Spacer()

                // Answer Buttons
                VStack(spacing: 15) {
                    ForEach(options, id: \.self) { name in
                        Button(action: {
                            checkAnswer(name)
                        }) {
                            Text(name)
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(buttonColor(for: name))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(showFeedback)
                    }
                }

                Spacer()
            } else if gameOver {
                 gameOverView()
            } else if people.isEmpty {
                 noDataView()
            } else {
                ProgressView()
            }
        }
        .padding(40)
        .navigationTitle("Game")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
           ToolbarItem(placement: .navigationBarTrailing) {
                Text("Score: \(score)")
                    .font(.headline)
            }
            ToolbarItem(placement: .navigationBarLeading){
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    
                }

            }
        }
        .onAppear {
            loadNextPerson()
        }
    }
    
    private func buttonColor(for name: String) -> Color {
        if !showFeedback {
            return .accentColor
        }

        if name == selectedName {
            return name == currentPerson?.name ? .green : .red
        } else if name == currentPerson?.name {
            return .green
        } else {
            return .accentColor
        }
    }

    private func loadNextPerson() {
        showFeedback = false
        selectedName = ""

        let availablePeople = people.filter { $0.imageName != nil }
        guard !availablePeople.isEmpty else {
            gameOver = true
            return
        }

        currentPerson = availablePeople.randomElement()

        var tempOptions: [String] = []
        if let currentName = currentPerson?.name {
            tempOptions.append(currentName)
        }

        while tempOptions.count < 4 && tempOptions.count < people.count {
            if let randomPerson = people.randomElement(),
               let randomName = randomPerson.name,
               !tempOptions.contains(randomName)
            {
                tempOptions.append(randomName)
            }
        }
        options = tempOptions.shuffled()
    }

    private func checkAnswer(_ selectedName: String) {
        self.selectedName = selectedName
        showFeedback = true

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        if selectedName == currentPerson?.name {
            generator.notificationOccurred(.success) // Success haptic
            score += 1
        } else {
            generator.notificationOccurred(.error) // Error haptic
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                loadNextPerson()
            }
        }
    }
    
    @ViewBuilder
       private func gameOverView() -> some View {
           VStack(spacing: 20) {
               Text("Game Over!")
                   .font(.largeTitle)
                   .fontWeight(.bold)
               Text("Your score: \(score)")
                   .font(.title2)
               Button("Restart Game") {
                    score = 0
                    gameOver = false
                    loadNextPerson()
               }
               .padding()
               .frame(maxWidth: .infinity)
               .background(Color.accentColor)
               .foregroundColor(.white)
               .cornerRadius(10)
           }
           .padding()
       }

    @ViewBuilder
       private func noDataView() -> some View {
          VStack{
               Text("No people in database.")
               Text("Add some in the Face Gallery")
           }
           .padding()
       }

    private func loadImageFromDocumentsDirectory(imageName: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(imageName)

        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            print("Error loading image from documents directory: \(error)")
            return nil
        }
    }
    @ViewBuilder
    private func errorImageView() -> some View {
        Image(systemName: "person.crop.circle.badge.exclamationmark")
            .resizable()
            .scaledToFit()
            .frame(width: 250, height: 250)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.secondary, lineWidth: 1))
    }
}
