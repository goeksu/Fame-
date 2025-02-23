import SwiftUI
import CoreData

struct FaceGalleryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Person.name, ascending: true)],
        animation: .default)
    private var people: FetchedResults<Person>

    @State private var isAddingPerson = false
    @State private var isEditingPerson = false
    @State private var editingPerson: Person? // Use optional here
    @State private var editedName: String = ""

    var body: some View {
        List {
            ForEach(people, id: \.id) { person in
                HStack {
                    if let imageName = person.imageName {
                        if imageName.hasPrefix("uuid-") {
                            if let uiImage = loadImageFromDocumentsDirectory(imageName: imageName) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } else {
                                errorImageView()
                            }
                        } else {
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        }
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                    }
                    Text(person.name ?? "Unknown")
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        editingPerson = person // Set the person to be edited
                        editedName = person.name ?? "" // Initialize editedName
                        isEditingPerson = true

                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deletePerson(person: person)
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
            }
        }
        .navigationTitle("Face Gallery")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isAddingPerson = true
                }) {
                    Label("Add Person", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingPerson) {
            AddPersonView(isPresented: $isAddingPerson)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $isEditingPerson) {
             if let editingPerson = editingPerson { //Safely unwrap
                  EditPersonView(isPresented: $isEditingPerson, person: editingPerson, editedName: $editedName)
                      .environment(\.managedObjectContext, viewContext)
             }
        }
    }

    private func deletePerson(person: Person) {
        viewContext.delete(person)
        saveContext()
    }

    private func deletePeople(offsets: IndexSet) {
        withAnimation {
            offsets.map { people[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
            // Consider showing an alert to the user here
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
