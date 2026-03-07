//
//  DrawingContentViewYT.swift
//  VibeSync
//
//  Created by Ayyoub on 6/3/2026.
//

import SwiftUI
import PhotosUI

struct DrawingContentViewYT: View {
    @State private var data = EditorData()
    @State private var showTools: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?
    

    var body: some View {
        NavigationStack{
            GeometryReader{geo in
//                EditorView(size: .init(width: 400, height: 400), data: data)
                
            }.toolbar{
                MenuItems()
                
                Menu("Export",systemImage: "square.and.arrow.up.fill"){
                    Button("As Image", ){
                        Task{
                            let rect = CGRect(origin: .zero, size: .init(width: 350, height: 670))
                            if let image = await data.exportAsImage(rect, scale: 2){
                                // Saving image
                                UIImageWriteToSavedPhotosAlbum(image,nil, nil, nil)
                            }
                        }
                    }
                    
                    Button("As Data", ){
                        Task{
                            if let markupData = await data.exportAsData(){
                                print(markupData)
                            }
                        }
                    }
                }
            }
            
        }
        
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { oldValue, newValue in
            guard let newValue else {return}
            
            Task {
                guard let data = try? await newValue.loadTransferable(type: Data.self),
                      let image = UIImage(data: data)
                else {
                    return
                }
                
                self.data.insertImage(image, rect: .init(origin: .zero, size: .init(width: 100, height: 100)))
                photoItem = nil
            }
        }
    }
    
    @ViewBuilder
    func MenuItems() -> some View {
        Menu("Items"){
            Button("Text"){
                data.insertText(.init("Text"), rect: .zero)
            }
            
            Menu("Shape"){
//                            Button("Rectangle")
            }
            
            Button("Image"){
                showImagePicker.toggle()
            }
            
            Button(showTools ? "Hide": "Show"){
                showTools.toggle()
                data.showPencilKitTools(showTools)
            }
        }
    }
}

#Preview {
    DrawingContentViewYT()
}
