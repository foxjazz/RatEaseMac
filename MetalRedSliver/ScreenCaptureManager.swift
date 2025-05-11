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
    @Published var infoMessages: [String] = []
    @Published var winTitles: [String] = []
    @Published var selectedTitle : String = "none"
    
    @Published var shouldCrop: Bool = false
    @Published var RectLeft: Int = 1
    @Published var RectTop: Int = 1
    @Published var RectHeight: Int = 700
    @Published var RectWidth: Int = 6
    @Published var RectMaxHeight: Int = 800
    @Published var RectMaxWidth: Int = 60
    
    let isAudioCaptureEnabled = false;
    let isAppAudioExcluded = true;
    var lm_streamConfig :SCStreamConfiguration? = nil
    private var selectedWindow: SCWindow? = nil
    var stream: SCStream?
    var frameDelegate: FrameCaptureDelegate? = nil
    
    private var streamConfiguration: SCStreamConfiguration {
        
        let streamConfig = SCStreamConfiguration()
        let x = RectLeft
        let y = RectTop
        let width = RectWidth
        let height = RectHeight
        streamConfig.sourceRect = CGRect(x: x, y: y, width: width, height: height)
        // Configure audio capture.
        streamConfig.capturesAudio = isAudioCaptureEnabled
        streamConfig.excludesCurrentProcessAudio = isAppAudioExcluded
        // Set the capture interval at 60 fps.
        streamConfig.minimumFrameInterval = CMTime(value: 20, timescale: 60)
        streamConfig.queueDepth = 1
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
                self.infoMessages.append("Error NoDisplay")
            }
            throw NSError(domain: "NoDisplay", code: 1)
        }
        RectMaxHeight = Int(targetWindow.frame.height)
        RectMaxWidth = Int(targetWindow.frame.width)
    }
    func updateSliverRect() async {
        do {
            let streamConfiguration = SCStreamConfiguration()
            let x = RectLeft
            let y = RectTop
            let width = RectWidth
            let height = RectHeight
            streamConfiguration.sourceRect = CGRect(x: x, y: y, width: width, height: height)
            
            try await self.stream?.stopCapture()
            try await self.stream?.updateConfiguration(streamConfiguration)
            try await self.stream?.startCapture()
        }catch {return}
        /*
        infoMessages.removeAll()
        if let oldStream = self.stream {
                do {
                    try await oldStream.stopCapture()
                    try? oldStream.removeStreamOutput(self.frameDelegate!, type: .screen)
                    
                    infoMessages.append("Stream stopped")
                } catch {
                    infoMessages.append("Failed to stop existing stream: \(error.localizedDescription)")
                }
        }
        
        
        do {
            guard let selectedWindow = self.selectedWindow else {
                        infoMessages.append("No selected window.")
                        return
                    }
            let filter = SCContentFilter(desktopIndependentWindow: selectedWindow)
            if self.frameDelegate == nil {
                let delegate = FrameCaptureDelegate()
                delegate.onImage = { image in
                    print("🖼 Updating Captured Image Size: \(image.width) x \(image.height)")
                    self.capturedImage = image
                }
                self.frameDelegate = delegate
                let newConfig = self.streamConfiguration
                     newConfig.sourceRect = CGRect(x: RectLeft, y: RectTop, width: RectWidth, height: RectHeight)
                let stream = SCStream(filter: filter, configuration: newConfig, delegate: self.frameDelegate)
                try stream.addStreamOutput(
                    delegate,
                    type: .screen,
                    sampleHandlerQueue: .main
                )
                self.stream = stream
            }

            //try await self.stream?.updateConfiguration(newConfig)
            try await self.stream?.startCapture()
            infoMessages.append("Updated sourceRect to x:\(RectLeft), y:\(RectTop), w:\(RectWidth), h:\(RectHeight)")
        } catch {
            infoMessages.append("Failed to update sourceRect: \(error.localizedDescription)")
        }
         */
    }
    func captureSliver(xPos: Int, width: Int = 6, height: Int = 400) async throws {
        DispatchQueue.main.async {
            self.infoMessages.removeAll()
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
                    self.infoMessages.append("Error NoDisplay")
                }
                throw NSError(domain: "NoDisplay", code: 1)
            }
            
            let filter = SCContentFilter(desktopIndependentWindow: targetWindow)
            self.selectedWindow = targetWindow
            
            
            let streamConfig = SCStreamConfiguration()
            
            streamConfig.sourceRect = CGRect(x: xPos, y: 0, width: 6, height: 300) // ✅ Full screen
            streamConfig.minimumFrameInterval = CMTime(value: 20, timescale: 60)
            streamConfig.queueDepth = 2
            
            self.lm_streamConfig = streamConfig
        
            //lm_StreamConfig.sourceRect = CGRect(x: RectLeft, y: RectTop, width: RectWidth, height: RectHeight)
            
            let crop = CropSettings(
                x: RectLeft,
                y: RectTop,
                width: RectWidth,
                height: RectHeight,
                shouldCrop: true
            )
            self.frameDelegate = FrameCaptureDelegate(cropSettings: crop)
            
            guard let frameDelegate = self.frameDelegate else { return }
  
            let stream = SCStream(filter: filter, configuration: self.lm_streamConfig ?? streamConfig, delegate: frameDelegate)
        
            self.stream = stream
            frameDelegate.onImage = { image in
                print("Received sample buffer, converting to image...")
//                let message = "lm_StreamConfig  x:\(lm_StreamConfig.sourceRect.origin.x), y:\(lm_StreamConfig.sourceRect.origin.y), w:\(lm_StreamConfig.sourceRect.size.width), h:\(lm_StreamConfig.sourceRect.size.height)"
//                print(message)
                
                print("🖼 Captured Image Size: \(image.width) x \(image.height)")
                
                
                self.capturedImage = image
//                let cropRect = CGRect(x: self.RectLeft, y: self.RectTop, width: self.RectWidth, height: self.RectHeight)
//                    if let cropped = image.cropping(to: cropRect) {
//                        print("🖼 Cropped Size: \(cropped.width) x \(cropped.height)")
//                        self.capturedImage = cropped
//                    } else {
//                        print("❌ Failed to crop image")
//                    }
                
            }

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
                self.infoMessages.append("Started capture for window: \(targetWindow.title ?? "no title here")")
                let message = "WITH Rect:  x:\(self.lm_streamConfig?.sourceRect.origin.x ?? 0), y:\(self.lm_streamConfig?.sourceRect.origin.y ?? 0), w:\(self.lm_streamConfig?.sourceRect.size.width ?? 6), h:\(self.lm_streamConfig?.sourceRect.size.height ?? 700)"
                self.infoMessages.append(message)
                // ✅ Add to list
            }
            do {
                
                try await stream.startCapture()
                DispatchQueue.main.async {
                    self.infoMessages.append("Finished capture for window: \(targetWindow.title ?? "no title here")") // ✅ Add to list
                }
            }
            catch{
                DispatchQueue.main.async {
                    self.infoMessages.append("Failing to startCapture() \(targetWindow.title ?? "no title here")") // ✅ Add to list
                }
            }
                // di
            
        } //do
        catch {
            DispatchQueue.main.async {
                self.infoMessages.append(error.localizedDescription) // ✅ Add to list
            }// dispatch
        } //catch
        
        
        //        try await stream.startCapture()
    } //function
    
}





