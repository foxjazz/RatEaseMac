//
//  ContentView.swift
//  MetalRedSliver
//
//  Created by Joe Dickinson on 09/05/2025.
//

import MetalKit
import SwiftUI
import CoreGraphics
import OSLog
import Combine
struct ContentView: View {
    
    @StateObject private var captureManager = ScreenCaptureManager()
    @State private var capturedImage: NSImage? = nil
    @State private var xPosition: CGFloat = 500
    @State private var errors: [String] = []
    //@State public var winTitles: [String] = []
    //@State public var selectedTitle : String = "None"
    @State var userStopped = false
    @State var disableInput = false
    @State var isUnauthorized = false
    @State private var isTitlesExpanded = false
    
    var body: some View {
        HStack{
            
            VStack {
                Text("Screen Area Info")
                    .font(.title)
                Text("RectLeft = \(captureManager.RectLeft)")
                Text("RectTop = \(captureManager.RectTop)")
                Text("RectWidth = \(captureManager.RectWidth)")
                Text("RectHeight = \(captureManager.RectHeight)")
                if let cgImage = captureManager.capturedImage {
                    let nsImage = NSImage(cgImage: cgImage, size: .zero) // ✅ Convert CGImage to NSImage
                    
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 800)
                } else {
                    Text("No image yet.")
                }
                
            }
            VStack{
                Text("selected title: \(captureManager.selectedTitle)")
                //DisclosureGroup("window titles", isExpanded: $isTitlesExpanded) {}
                
                Picker("Select a Window", selection: $captureManager.selectedTitle) {
                    ForEach(captureManager.winTitles, id: \.self) { title in
                        Text(title).tag(title)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: captureManager.selectedTitle) {
                    Task{
                        try await captureManager.bubbleUpMaxFrame()
                    }
                }// Dropdown-style
            Text("Left")
                Slider(
                    value: Binding(
                        get: { Double(captureManager.RectLeft) },
                        set: { captureManager.RectLeft = Int($0) }
                    ),
                    in: 0...Double(captureManager.RectMaxWidth)
                            )
                    .padding()
                Text("Top")
                Slider(
                    value: Binding(
                        get: { Double(captureManager.RectTop) },
                        set: { captureManager.RectTop = Int($0) }
                    ),
                    in: 0...Double(captureManager.RectMaxHeight / 4)
                            )
                    .padding()
                Text("Height")
                    Slider(
                        value: Binding(
                            get: { Double(captureManager.RectHeight) },
                            set: { captureManager.RectHeight = Int($0) }
                        ),
                        in: 0...Double(captureManager.RectMaxHeight)
                                )
                        .padding()
                Text("Width  should be < 10")
                    Slider(
                        value: Binding(
                            get: { Double(captureManager.RectWidth) },
                            set: { captureManager.RectWidth = Int($0) }
                        ),
                        in: 0...60
                                )
                        .padding()
                Button("Check Capture") {
                    Task{
                        do {
                            try await captureManager.captureSliver(xPos: 100)
                        } catch {
                            print("❌ Capture error: \(error)")
                        }
                    }
                }
                
            }
        }
        .onAppear {
            Task{
                do{
                    //try await captureManager.populateWindowTitles()
                    try await captureManager.simPopTitles()
                }
                catch{print("X onAppear error")}
                isTitlesExpanded = true
            }
           
        }
    
    }
    
}
func nsImage(from cgImage: CGImage) -> NSImage {
    let size = NSSize(width: cgImage.width, height: cgImage.height)
    return NSImage(cgImage: cgImage, size: size)
}

