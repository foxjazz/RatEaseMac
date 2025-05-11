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
    func stream(
      _ stream: SCStream,
      didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
      of outputType: SCStreamOutputType
    ) {
        print("⚡ FrameCaptureDelegate received a buffer")
        guard outputType == .screen,
              let pixelBuffer = sampleBuffer.imageBuffer else
        {
            print("❌ No valid pixel buffer found")
            return }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            // Deliver your CGImage to wherever you need it:
            print("✅ Image successfully extracted!")
            onImage?(cgImage)
        }
        else {
                print("❌ Failed to convert CIImage to CGImage")
            }
        // Stop after one frame
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//            Task {
//                try? await stream.stopCapture()
//            }
        //}
        
       
    }

    /// Closure for handing the captured image back
    var onImage: ((CGImage) -> Void)?
}
