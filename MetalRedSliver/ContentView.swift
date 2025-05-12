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

    @State private var errors: [String] = []
    //@State public var winTitles: [String] = []
    //@State public var selectedTitle : String = "None"
    @State var userStopped = false
    @State var disableInput = false
    @State var isUnauthorized = false
    @State private var isTitlesExpanded = false
    @State private var lastPlayTime = Date.distantPast
    
    var body: some View {
        
        HStack{
            
            VStack {
                HStack{
                    Text("Capture Status")
                        .font(.title)
                    if (captureManager.captureIsActive ){
                        Circle()
                            .fill(.green)
                            .frame(width: 20, height: 20)
                        
                    }else{
                        Circle()
                            .fill(.red)
                            .frame(width: 20, height: 20)
                    }
                            
                    
                }.padding()
                HStack{
                    Text("RectLeft = \(captureManager.RectLeft)")
                    Text("RectTop = \(captureManager.RectTop)")
                }.padding()
                HStack{
                    Text("RectWidth = \(captureManager.RectWidth)")
                    Text("RectHeight = \(captureManager.RectHeight)")
                }.padding()
                if let cgImage = captureManager.capturedImage {
                    Text("Captured image dimensions: \(cgImage.width) x \(cgImage.height)")
                    let nsImage = NSImage(cgImage: cgImage, size: .zero) // ✅ Convert CGImage to NSImage
                    
//                    Image(nsImage: nsImage)
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .frame(width: 30, height: 800)
                    Image(nsImage: nsImage)
                        .interpolation(.none) // Optional: prevent smoothing
                        .frame(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
                    Text( "image-size : width: \(cgImage.width), height: \(cgImage.height)")
     
                } else {
                    Text("No image yet.")
                    Color.gray // Placeholder while waiting for the actual image
                           .frame(width: 30, height: 800)
                           .cornerRadius(8)
                           .overlay(Text("No image yet").foregroundColor(.white))
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
                    in: 0...Double(captureManager.RectMaxHeight)
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
                        
                HStack{
                    Button("Check Capture") {
                        Task{
                            do {
                                try await captureManager.captureSliver(x: captureManager.RectLeft, y: captureManager.RectTop, width: captureManager.RectWidth, height: captureManager.RectHeight)
                            } catch {
                                print("❌ Capture error: \(error)")
                            }
                        }
                    }
                    Button("Update Image Rectangle"){
                        
                        Task{
                            try await captureManager.stream?.stopCapture()
                            captureManager.captureIsActive = false
                            try await captureManager.captureSliver(x: captureManager.RectLeft, y: captureManager.RectTop, width: captureManager.RectWidth, height: captureManager.RectHeight)
                        }
                        
                    }
                    Button("Save settings"){
                        captureManager.persistSettings()
                        
                    }
                    Button("crop = \(captureManager.shouldCrop ? "true" : "false")"){
                        captureManager.shouldCrop.toggle()
                    }
                }.padding()
                ForEach(captureManager.infoMessages, id: \.self) { msg in
                    Text(msg).tag(msg)
                }
                ForEach(captureManager.infoSize, id: \.self){msg in
                    Text(msg).tag(msg)
                }
                
            }
        }
        .onAppear {
            Task{
                do{
                    captureManager.restoreSettings()
                    let title = captureManager.selectedTitle
                    if title.isEmpty || title == "none"{
                        try await captureManager.populateWindowTitles()
                    }
                    else {
                        try await captureManager.captureSliver(x: captureManager.RectLeft, y: captureManager.RectTop, width: captureManager.RectWidth, height: captureManager.RectHeight)
                    }
                    //try await captureManager.simPopTitles()
                }
                catch{print("X onAppear error")}
                isTitlesExpanded = true
            }
           
        }
        .onReceive(captureManager.$redDetected) { isRed in
            let now = Date()
            if (isRed && now.timeIntervalSince(lastPlayTime) >= 10) {
                NSSound(named: NSSound.Name("Submarine"))?.play()
            }
        }
    
        
    } //body view
    
}  //content view

func nsImage(from cgImage: CGImage) -> NSImage {
    let size = NSSize(width: cgImage.width, height: cgImage.height)
    return NSImage(cgImage: cgImage, size: size)
}

