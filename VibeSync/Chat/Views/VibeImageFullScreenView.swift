//
//  VibeImageFullScreenView.swift
//  VibeSync
//
//  Created by Ayyoub on 15/4/2026.
//

import SwiftUI

struct VibeImageFullScreenView: View {
    @Environment(\.dismiss) private var dismiss
    var message: VibeMessage
    @State private var model: VibeImageFullScreenViewModel

    @State private var reportManager = ReportManager()
    @State private var showSuccessAlert = false

    init(message: VibeMessage) {
        self.message = message
        _model = State(
            wrappedValue: VibeImageFullScreenViewModel(
                imageURL: message.imageURL
            )
        )
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // IMAGE
            if let img = model.image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .tint(.white)
            }

            // TOP BAR
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.black.opacity(0.4))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Button {
                        model.saveImage()
                    } label: {
                        Image(systemName: saveIconName)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
                .padding()

                Spacer()
            }

            // BOTTOM ACTIONS
            VStack {
                Spacer()

                Button {
                    Task {
                        await reportManager.reportMessage(
                            messageId: message._id
                        )
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "flag")
                        Text("Report")
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.red.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
        }
        .onChange(of: reportManager.state) { _, state in
            if case .success = state {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    reportManager.state = .idle
                }
            }
        }

        .onChange(of: reportManager.state) { _, state in
            if case .success = state {
                showSuccessAlert = true
            }
        }
        .alert("Report submitted", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Report submitted. Our team will review it.")
        }
    }

    private var saveIconName: String {
        switch model.saveState {
        case .idle:
            return "square.and.arrow.down"
        case .saving:
            return "hourglass"
        case .success:
            return "checkmark"
        case .failure:
            return "xmark"
        }
    }

}

#Preview {
    VibeImageFullScreenView(
        message: VibeMessage(
            _id: "asd",
            senderID: "123",
            receiverID: "345",
            imageURL: "https://vibesync.ayyoub.io/imgs/camera.png",
            resizedImageURL: "https://vibesync.ayyoub.io/imgs/camera.png",
            createdAt: "2026-04-15T14:32:10.123Z",
            updatedAt: ""
        )
    )
}
