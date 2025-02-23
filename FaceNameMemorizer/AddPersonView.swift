import SwiftUI
import CoreData
import PhotosUI
import Vision

struct DetectedFace {
    let boundingBox: CGRect
    let image: UIImage
}

extension UIImage.Orientation {
    func toCGImageOrientation() -> CGImagePropertyOrientation {
        switch self {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

extension DetectedFace: Equatable {
    static func == (lhs: DetectedFace, rhs: DetectedFace) -> Bool {
        return lhs.boundingBox == rhs.boundingBox
    }
}

struct AddPersonView: View {
    @Binding var isPresented: Bool
    @State private var name: String = ""
    @Environment(\.managedObjectContext) private var viewContext

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil

    @State private var detectedFaces: [DetectedFace] = []
    @State private var selectedFace: DetectedFace? = nil
    @State private var showingFaceSelection = false
    @State private var showingNoFacesAlert = false
    @State private var showingNameAlert = false

    @State private var photoSelected = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()) {
                            Text("Select Photo")
                        }
                }

                if photoSelected {
                    Section {
                        if showingFaceSelection {
                            faceSelectionView()
                        } else if let selectedImageData,
                                  let uiImage = UIImage(data: selectedImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                        }
                    }

                    Section {
                        TextField("Name", text: $name)
                    }
                }
            }
            .navigationTitle("Add Person")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if name.isEmpty {
                            showingNameAlert = true
                        } else {
                            saveSelectedFace()
                        }
                    }
                    .disabled(name.isEmpty || selectedFace == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        isPresented = false
                    }
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImageData = data
                        detectFaces(in: uiImage)
                        selectedFace = nil
                        photoSelected = true
                    }
                }
            }
            .alert("No Faces Detected", isPresented: $showingNoFacesAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("No faces were detected. Please choose another image.")
            }
            .alert("Name Required", isPresented: $showingNameAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a name.")
            }
        }
    }

    private func detectFaces(in image: UIImage) {
        guard let ciImage = CIImage(image: image) else { return }

        let request = VNDetectFaceRectanglesRequest { request, error in
            if let error = error {
                print("Face detection error: \(error)")
                return
            }

            guard let results = request.results as? [VNFaceObservation] else { return }

            if results.isEmpty {
                DispatchQueue.main.async {
                    self.showingNoFacesAlert = true
                }
                return
            }

            var detectedFaces: [DetectedFace] = []

            for faceObservation in results {
                let boundingBox = faceObservation.boundingBox

                if let croppedImage = cropImageToFace(uiImage: image, faceObservation: faceObservation){
                    let face = DetectedFace(boundingBox: boundingBox, image: croppedImage)
                    detectedFaces.append(face)
                }
            }

            DispatchQueue.main.async {
                self.detectedFaces = detectedFaces
                if detectedFaces.count > 1 {
                    self.showingFaceSelection = true
                } else if detectedFaces.count == 1 {
                    self.selectedFace = detectedFaces.first
                }
            }
        }

        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: image.imageOrientation.toCGImageOrientation())

        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform face detection: \(error)")
        }
    }

    @ViewBuilder
    private func faceSelectionView() -> some View {
        VStack {
            Text("Select the face!")
                .font(.headline)
                .padding(.bottom)

            ScrollView(.horizontal) {
                HStack {
                    ForEach(detectedFaces.indices, id: \.self) { index in
                        let face = detectedFaces[index]
                        Image(uiImage: face.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedFace?.boundingBox == face.boundingBox ? Color.green : Color.clear, lineWidth: 4)
                            )
                            .onTapGesture {
                                selectedFace = face
                            }
                    }
                }
            }
        }
    }

    private func cropImageToFace(uiImage: UIImage, faceObservation: VNFaceObservation) -> UIImage? {

        let boundingBox = faceObservation.boundingBox

        let x = boundingBox.origin.x * uiImage.size.width
        let y = (1 - boundingBox.origin.y - boundingBox.size.height) * uiImage.size.height
        let width = boundingBox.size.width * uiImage.size.width
        let height = boundingBox.size.height * uiImage.size.height

        let cropRect = CGRect(x: x, y: y, width: width, height: height)

        guard let cgImage = uiImage.cgImage?.cropping(to: cropRect) else {
            return nil
        }

        let croppedUIImage = UIImage(cgImage: cgImage)

        return croppedUIImage
    }


    private func saveSelectedFace() {
        guard let selectedFace = selectedFace else {
            return
        }

        withAnimation {
            let newPerson = Person(context: viewContext)
            newPerson.name = name

            if let imageName = saveImageToDocumentsDirectory(image: selectedFace.image) {
                newPerson.imageName = imageName
            }

            newPerson.id = UUID()

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error saving to Core Data: \(nsError), \(nsError.userInfo)")
            }
            isPresented = false
        }
    }


    private func saveImageToDocumentsDirectory(image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "uuid-" + UUID().uuidString + ".jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("Error saving image to documents directory: \(error)")
            return nil
        }
    }
}
