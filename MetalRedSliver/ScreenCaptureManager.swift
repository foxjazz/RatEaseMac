//
//  ScreenCaptureManager.swift
//  MetalRedSliver
//
//  Created by Joe Dickinson on 09/05/2025.
//
import Foundation
import ScreenCaptureKit
import CoreGraphics
import AVFoundation

@MainActor
class ScreenCaptureManager : ObservableObject {
    @Published var capturedImage: CGImage?
    @Published var errorMessages: [String] = []
    @Published var winTitles: [String] = []
    @Published var selectedTitle : String = "none"
    
    @Published var RectLeft: Int = 0
    @Published var RectTop: Int = 0
    @Published var RectHeight: Int = 10
    @Published var RectWidth: Int = 6
    @Published var RectMaxHeight: Int = 300
    @Published var RectMaxWidth: Int = 300
    
    let isAudioCaptureEnabled = false;
    let isAppAudioExcluded = true;
    
    
    var selectedWindow : SCWindow?
    
    //@ObservedObject var screenRecorder: ScreenRecorder
    private var streamConfiguration: SCStreamConfiguration {
        
        let streamConfig = SCStreamConfiguration()
        let xPositive = 10
        streamConfig.sourceRect = CGRect(x: xPositive, y: 0, width: 6, height: 300)
        // Configure audio capture.
        streamConfig.capturesAudio = isAudioCaptureEnabled
        streamConfig.excludesCurrentProcessAudio = isAppAudioExcluded
       
        // Configure the display content width and height.
//        if captureType == .display, let display = selectedDisplay {
//            streamConfig.width = display.width * scaleFactor
//            streamConfig.height = display.height * scaleFactor
//        }
        
        // Configure the window content width and height.
        
        if let window = selectedWindow {
                
                streamConfig.width = Int(window.frame.width)
                streamConfig.height = Int(window.frame.height)
                print("success: h/w is now set with streamConfig")
            } else {
                streamConfig.width = 5  // Default fallback resolution
                streamConfig.height = 5
                print("⚠️ Warning: `selectedWindow` is nil, using default values!")
            }
        
        
        // Set the capture interval at 60 fps.
        streamConfig.minimumFrameInterval = CMTime(value: 10, timescale: 60)
        
        // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        streamConfig.queueDepth = 2
        
        return streamConfig
    }
    
    func simPopTitles() async throws {
        var titleList: [String] = []
        do {
            
            for x in 1...10 {
                titleList.appendUnique("title \(x)")
            }
            DispatchQueue.main.async {
                self.winTitles = titleList
            }
        }
    }
    func populateWindowTitles() async throws{
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            let windows = content.windows
            var titleList: [String] = []
            
            for window in windows {
                titleList.appendUnique("\(window.title ?? "blank")")
//                DispatchQueue.main.async {
//                    self.winTitles.appendUnique("\(window.title ?? "blank")")
//                }
            }
            DispatchQueue.main.async {
                self.winTitles = titleList
            }
            
        } catch {
            print("populatewindowtitles error function")
        }
    }
    func bubbleUpMaxFrame() async throws{
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let targetWindow = content.windows.first(where: { $0.title == selectedTitle }) else {
            DispatchQueue.main.async {
                self.errorMessages.append("Error NoDisplay")
            }
            throw NSError(domain: "NoDisplay", code: 1)
        }
        RectMaxHeight = Int(targetWindow.frame.height)
        RectMaxWidth = Int(targetWindow.frame.width)
    }
    
    func captureSliver(xPos: Int, width: Int = 6, height: Int = 400) async throws {
        DispatchQueue.main.async {
            self.errorMessages.removeAll()
        }
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            let windows = content.windows
            var titleList: [String] = []
            
            for window in windows {
                titleList.append("\(window.title ?? "blank")")
            }
            
            
            // guard let selectedWindow = windows.first(where: { $0.title == "EVE - foxjazz" }) else {
            guard let targetWindow = windows.first(where: { $0.title == selectedTitle }) else {
                DispatchQueue.main.async {
                    self.errorMessages.append("Error NoDisplay")
                }
                throw NSError(domain: "NoDisplay", code: 1)
            }
            
            let filter = SCContentFilter(desktopIndependentWindow: targetWindow)
            self.selectedWindow = targetWindow
            let lm_streamConfig = streamConfiguration
            
            //streamConfig.sourceRect = CGRect(x: xPos, y: 0, width: 6, height: 300) // ✅ Full screen
            //config.minimumFrameInterval = CMTime(value: 300, timescale: 1000)
            //streamConfig.minimumFrameInterval = CMTime(value: 10, timescale: 60)
            //streamConfig.queueDepth = 2
            
            
            
            let frameDelegate = FrameCaptureDelegate()
            let stream = SCStream(filter: filter, configuration: lm_streamConfig, delegate: frameDelegate)
            frameDelegate.onImage = { image in
                print("Received sample buffer, converting to image...")
                self.capturedImage = image
                DispatchQueue.main.async {
                    self.errorMessages.append("onImage callback, stopping capture") // ✅ Add to list
                }
                Task {
                        do {
                            try await stream.stopCapture()
                            print("✅ Stream successfully stopped after receiving an image!")
                        } catch {
                            print("❌ Error stopping stream: \(error.localizedDescription)")
                        }
                    }
            }
            
            //            try await stream.updateConfiguration(lm_streamConfig)
            //            try await stream.updateContentFilter(filter)
            do {
                try stream.addStreamOutput(
                    frameDelegate,
                    type: .screen,
                    sampleHandlerQueue: .main
                )
                
                print("✅ Successfully added FrameCaptureDelegate!")
            } catch {
                print("❌ Failed to add FrameCaptureDelegate: \(error.localizedDescription)")
            }
        
            
            print("Starting capture for window: \(String(describing: targetWindow.title))")
            DispatchQueue.main.async {
                self.errorMessages.append("Started capture for window: \(targetWindow.title ?? "no title here")") // ✅ Add to list
            }
            do {
                try await stream.startCapture()
                DispatchQueue.main.async {
                    self.errorMessages.append("Finished capture for window: \(targetWindow.title ?? "no title here")") // ✅ Add to list
                }
            }
            catch{
                DispatchQueue.main.async {
                    self.errorMessages.append("Failing to startCapture() \(targetWindow.title ?? "no title here")") // ✅ Add to list
                }
            }
                // di
            
        } //do
        catch {
            DispatchQueue.main.async {
                self.errorMessages.append(error.localizedDescription) // ✅ Add to list
            }// dispatch
        } //catch
        
        
        //        try await stream.startCapture()
    } //function
    
}





