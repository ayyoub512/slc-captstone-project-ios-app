////
////  DrawingView2.swift
////  VibeSync
////
////  Created by Ayyoub on 25/2/2026.
////
//
//import SwiftUI
//import PencilKit
//
//struct DrawingView2: View {
//    @State var drawing: PKDrawing = PKDrawing()
//    
//    var body: some View {
//        
//        VStack{
//            HStack{
//                Text("Draw a dog ")
//                    .font(.title)
//                Spacer()
//                Button{
//                    drawing = PKDrawing()
//                }label: {
//                    Text("Clear")
//                }
//            }
//            
//            CanvasView2(drawing: $drawing)
//        }
//        .padding()
//        .background(Color(.secondarySystemBackground))
//    }
//}
//
//
//// MARK: Canvas View
//
//
//struct CanvasView2: UIViewRepresentable{
//    @Binding var drawing: PKDrawing
//    let toolPicker = PKToolPicker()
//    
//    init(drawing: Binding<PKDrawing>){
//        _drawing = drawing
//    }
//    
//    func makeUIView(context: Context) -> some PKCanvasView {
//        let canvasView = PKCanvasView()
//        canvasView.drawingPolicy = .anyInput
//        canvasView.drawing = drawing
//        toolPicker.setVisible(true, forFirstResponder: canvasView)
//        toolPicker.addObserver(canvasView)
//        canvasView.becomeFirstResponder()
//        return canvasView
//    }
//    
//    func updateUIView(_ uiView: UIViewType, context: Context) {
//        if uiView.drawing != drawing {
//            uiView.drawing = drawing
//        }
//    }
//}
//
//extension CanvasView2 {
//    class Coordinator {
//        
//    }
//}
//
//
//#Preview {
//    DrawingView2()
//}
