//
//  FrameCaptureDelegate.swift
//  MetalRedSliver
//
//  Created by Joe Dickinson on 09/05/2025.
//
import Foundation
import ScreenCaptureKit
import AVFoundation
import CoreImage

class FrameCaptureDelegate: NSObject, SCStreamOutput, SCStreamDelegate {
    /// Called whenever a new sample buffer arrives
    
    
    let cropSettings: CropSettings
    init(cropSettings: CropSettings) {
            self.cropSettings = cropSettings
        }

    func stream(
      _ stream: SCStream,
      didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
      of outputType: SCStreamOutputType
    ) {
        // print("⚡ FrameCaptureDelegate received a buffer")
        guard outputType == .screen,
              let pixelBuffer = sampleBuffer.imageBuffer else
        {
            print("❌ No valid pixel buffer found")
            return }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }

                if cropSettings.shouldCrop {
                    let cropRect = CGRect(
                        x: cropSettings.x,
                        y: cropSettings.y,
                        width: cropSettings.width,
                        height: cropSettings.height
                    )

                    if let cropped = cgImage.cropping(to: cropRect) {
                        onImage?(cropped)
                    } else {
                        print("❌ Failed to crop")
                        onImage?(cgImage)
                    }
                } else {
                    onImage?(cgImage)
                }
        
        // Stop after one frame
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//            Task {
//                try? await stream.stopCapture()
//            }
        //}
        
       
    }
    

    
    var onImage: ((CGImage) -> Void)?
    /// Closure for handing the captured image back
    //var onImage: ((CGImage) -> Void)?
}
struct CropSettings {
    var x: Int
    var y: Int
    var width: Int
    var height: Int
    var shouldCrop: Bool
}
