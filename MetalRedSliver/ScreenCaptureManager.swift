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
    
    @Published var redDetected: Bool = false
    @Published var shouldCrop: Bool = true
    @Published var RectLeft: Int = 1
    @Published var RectTop: Int = 1
    @Published var RectHeight: Int = 700
    @Published var RectWidth: Int = 6
    @Published var RectMaxHeight: Int = 800
    @Published var RectMaxWidth: Int = 60
    @Published var infoSize: [String] = []
    @Published var captureIsActive: Bool = false
    let isAudioCaptureEnabled = false;
    let isAppAudioExcluded = true;
    var lm_streamConfig :SCStreamConfiguration? = nil
    private var selectedWindow: SCWindow? = nil
    var stream: SCStream?
    var frameDelegate: FrameCaptureDelegate? = nil
    
    private var streamConfiguration : SCStreamConfiguration
    {
        
        let streamConfig = SCStreamConfiguration()
        let x = 0
        let y = 0
        let width = RectMaxWidth
        let height = RectMaxHeight
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
            }
            DispatchQueue.main.async {
                self.winTitles = titleList
            }
            
        } catch {
            print("populatewindowtitles error function")
        }
    }
    private func setInfoSize(s : String){
        DispatchQueue.main.async {
            self.infoSize.appendQueue(s)
        }
    }
    
    private func setInfo(msg: String){
        DispatchQueue.main.async{

            self.infoMessages.appendQueue(msg)
        }
    }
    private func setCaptureStatus(status: Bool){
        self.captureIsActive = status
    }
    /* ******************************************************************
     *********************  Wire up MaxFrame size ****************************
     ********************************************************************/
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
    /* ******************************************************************
     *********************  Update Rectangle ****************************
     ********************************************************************/
    func updateSliverRect() async {
        do {
            let streamConfiguration = SCStreamConfiguration()
            let x = RectLeft
            let y = RectTop
            let width = RectWidth
            let height = RectHeight
            streamConfiguration.sourceRect = CGRect(x: x, y: y, width: width, height: height)
            setInfoSize(s: "updateSliver :: rect: x: \(x), y: \(y), width: \(width), height: \(height)")
            try await self.stream?.stopCapture()
            setCaptureStatus(status: false)
//            guard let fd = self.frameDelegate else {print ("Error on update"); return}
//            fd.onImage = { image in
//                    print("🖼 Updated Captured Image Size: \(image.width) x \(image.height)")
//                    self.setCaptureStatus(status: true)
//                    self.setInfoSize(s: "freamDelegate.onImage ## width: \(image.width), height: \(image.height)")
//                    self.capturedImage = image
//                    let hasRed = self.containsRedPixels(in: image)
//                        DispatchQueue.main.async {
//                            self.redDetected = hasRed
//                        }
//                }
//            
//            
//            try self.stream?.addStreamOutput(
//                fd,
//                type: .screen,
//                sampleHandlerQueue: .main
//            )
            try await self.stream?.updateConfiguration(streamConfiguration)
            try await self.stream?.startCapture()
           // try await self.captureSliver(x: x, y: y, width: width, height: height)
        }catch {return}
        
    }
    /* ******************************************************************
     *********************  Capture Sliver ****************************
     ********************************************************************/
    func captureSliver(x: Int,y: Int , width: Int, height: Int) async throws {
        //try await self.stream?.stopCapture()
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
           
//            streamConfig.sourceRect = CGRect(x: x, y: y, width: width, height: height) // ✅ Full screen
//            setInfoSize(s: "captureSliver -- x: \(x), y: \(y), width: \(width), height: \(height)")
//            streamConfig.minimumFrameInterval = CMTime(value: 20, timescale: 60)
//            streamConfig.queueDepth = 1
            
            self.lm_streamConfig = streamConfig
        
            //lm_StreamConfig.sourceRect = CGRect(x: RectLeft, y: RectTop, width: RectWidth, height: RectHeight)
            
            let crop = CropSettings(
                x: RectLeft,
                y: RectTop,
                width: RectWidth,
                height: RectHeight,
                Crop: self.shouldCrop
            )
            self.frameDelegate = FrameCaptureDelegate(cropSettings: crop)
            
            guard let frameDelegate = self.frameDelegate else {
                print("❌ no valid frameDelegate")
                return
            }
            
            let stream = SCStream(filter: filter, configuration: self.lm_streamConfig ?? streamConfig, delegate: frameDelegate)
        
            self.stream = stream
            //frameDelegate.listener = self
            frameDelegate.onImage = { image in

                let msg1 = "🖼 Captured Image Size: \(image.width) x \(image.height)"
                print(msg1)
                self.setInfo(msg: msg1)
                self.setCaptureStatus(status: true)
                self.setInfoSize(s: "freamDelegate.onImage ## width: \(image.width), height: \(image.height)")
                self.capturedImage = image
                let hasRed = self.containsRedPixels(in: image)
                    DispatchQueue.main.async {
                        self.redDetected = hasRed
                    }
            }
            do {
                try stream.addStreamOutput(
                    frameDelegate,
                    type: .screen,
                    sampleHandlerQueue: .main
                )
                //self.setCaptureStatus(status: true)
                //print("✅ Successfully added FrameCaptureDelegate!")
            } catch {
                self.setCaptureStatus(status: false)
                //print("❌ Failed to add FrameCaptureDelegate: \(error.localizedDescription)")
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
    private func containsRedPixels(in cgImage: CGImage) -> Bool {
        guard let dataProvider = cgImage.dataProvider,
              let pixelData = dataProvider.data else {
            return false
        }

        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow

        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * bytesPerRow + x * bytesPerPixel
                let r = data[pixelIndex]
                let g = data[pixelIndex + 1]
                let b = data[pixelIndex + 2]
                let a = data[pixelIndex + 3]

                // Simple "red-ish" logic: red is dominant and not transparent
                if r > 0x75 && g < 0x15  && b < 0x15 && a > 0 {
                    return true
                }
            }
        }

        return false
    }
    func persistSettings() {
        let config = AppConfig(
            selectedTitle: self.selectedTitle,
            rectLeft: self.RectLeft,
            rectTop: self.RectTop,
            rectWidth: self.RectWidth,
            rectHeight: self.RectHeight
        )
        saveConfig(config)
    }
    func restoreSettings() {
        if let config = loadConfig() {
            selectedTitle = config.selectedTitle
            RectLeft = config.rectLeft
            RectTop = config.rectTop
            RectWidth = config.rectWidth
            RectHeight = config.rectHeight
        }
    }
    private func saveConfig(_ config: AppConfig) {
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: configFileURL())
            print("✅ Config saved.")
        } catch {
            print("❌ Failed to save config: \(error)")
        }
    }
    private func loadConfig() -> AppConfig? {
        do {
            let data = try Data(contentsOf: configFileURL())
            let config = try JSONDecoder().decode(AppConfig.self, from: data)
            print("✅ Config loaded.")
            return config
        } catch {
            print("⚠️ No config file or failed to load: \(error)")
            return nil
        }
    }
}

//extension ScreenCaptureManager: FrameCaptureDelegateListener {
//    func didDetectRedPixel() {
//        print("🔊 Red pixel detected — play sound")
//        NSSound(named: NSSound.Name("Submarine"))?.play()
//    }
//}



