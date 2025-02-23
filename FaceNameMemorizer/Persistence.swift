import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FaceNameModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true

        // Check if this is the first launch
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            addDefaultData(context: container.viewContext)
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore") // Mark as launched
        }
    }

    // default data
    func addDefaultData(context: NSManagedObjectContext) {
        let names = ["Alice", "Bob", "Charlie", "Daisy", "Emma"]
        let imageNames = ["alice", "bob", "charlie", "daisy", "emma"]

        for i in 0..<names.count {
            let newPerson = Person(context: context)
            newPerson.name = names[i]
            newPerson.imageName = imageNames[i]
            newPerson.id = UUID()
        }

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // We keep the previewData for the previews, but its no longer related with the persistance.
        previewData(context: viewContext)
        return result
    }()
    
    // Helper function to create some default data FOR PREVIEW
    static func previewData(context: NSManagedObjectContext) {
        let names = ["Alice", "Bob", "Charlie", "Daisy", "Emma"]
        let imageNames = ["alice.jpg", "bob.jpg", "charlie.jpg","daisy.jpg", "emma.jpg"]

        for i in 0..<names.count {
            let newPerson = Person(context: context)
            newPerson.name = names[i]
            newPerson.imageName = imageNames[i]
            newPerson.id = UUID()
        }

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
