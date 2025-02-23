import SwiftUI

struct EditPersonView: View {
    @Binding var isPresented: Bool
    @ObservedObject var person: Person // Use @ObservedObject
    @Binding var editedName: String // Get a binding to editedName
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Image")) {
                    if let imageName = person.imageName {
                        if imageName.hasPrefix("uuid-") {
                            if let uiImage = loadImageFromDocumentsDirectory(imageName: imageName) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                errorImageView()
                            }
                        } else {
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        }
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                    }
                }

                Section(header: Text("Edit Name")) {
                    TextField("Name", text: $editedName)
                }
            }
            .navigationTitle("Edit Person")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func saveChanges() {
           person.name = editedName // Update the name

           // Defer the save to the next run loop
           DispatchQueue.main.async {
               do {
                   try viewContext.save()
                   isPresented = false // Dismiss after successful save
               } catch {
                   let nsError = error as NSError
                   print("Unresolved error \(nsError), \(nsError.userInfo)")
                   // Show an alert to the user, ideally
               }
           }
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
            .scaledToFill()
            .frame(width: 50, height: 50)
    }
}
