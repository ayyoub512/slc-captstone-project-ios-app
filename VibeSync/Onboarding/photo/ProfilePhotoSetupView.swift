import PhotosUI
import SwiftUI

struct ProfilePhotoSetupView: View {
    @AppStorage(K.shared.onBoardingProfileImageURL) var imageURL: URL?

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
//    @State private var imageURL: URL?
    
    var onContinue: (URL?) -> Void

    var body: some View {
        VStack(spacing: 24) {

            Spacer()
                .frame(height: 20)

            // Title
            VStack(spacing: 12) {
                Text("Add a face to the name")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 28, weight: .semibold))

                Text("This helps your friends recognize you.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            }

            Spacer()

            // MARK: - Avatar
            VStack {
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 140, height: 140)

                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                    }
                }
                .onTapGesture {
                    // optional: also open picker on tap
                }
            }

            // MARK: - Photo Picker
            PhotosPicker(
                selection: $selectedItem,
                matching: .images
            ) {
                Text(selectedImage == nil ? "Add Photo" : "Change Photo")
                    .foregroundStyle(.brandPrimary)
                    .font(.headline)
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    guard
                        let data = try? await newItem?.loadTransferable(
                            type: Data.self
                        ),
                        let uiImage = UIImage(data: data)
                    else { return }

                    selectedImage = uiImage

                    // persist immediately
                    imageURL = try? OnboardingImageStore.save(uiImage)
                }
            }

            Spacer()

            // MARK: - Actions
            VStack(spacing: 12) {

                Button {
                    onContinue(imageURL)
                } label: {
                    HStack(spacing: 8) {
                        Text("Continue")
                        
                        Image(systemName: "arrow.right")
                    }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandPrimary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    onContinue(nil)
                } label: {
                    Text("Skip")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

struct OnboardingImageStore {

    static func save(_ image: UIImage) throws -> URL {
        let data = image.jpegData(compressionQuality: 0.8)!

        let url = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("onboarding_profile.jpg")

        try data.write(to: url, options: .atomic)
        return url
    }
}

#Preview {
    ProfilePhotoSetupView { url in

    }

}
