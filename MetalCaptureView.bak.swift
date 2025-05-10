//
//  MetalCaptureView.swift
//  MetalRedSliver
//
//  Created by Joe Dickinson on 09/05/2025.
//
import MetalKit
import SwiftUI
import CoreGraphics
import MetalKit
import AppKit
import SwiftData
import ScreenCaptureKit



struct MetalRedSilver: App {
    
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
//class MetalCaptureView: MTKView {
//    var commandQueue: MTLCommandQueue?
//
//    required init(coder: NSCoder) {
//        super.init(coder: coder)
//        self.device = MTLCreateSystemDefaultDevice()
//        self.commandQueue = self.device?.makeCommandQueue()
//    }
//
//    override func draw(_ rect: CGRect) {
//        guard let drawable = currentDrawable else { return }
//        let commandBuffer = commandQueue?.makeCommandBuffer()
//        let renderPassDescriptor = MTLRenderPassDescriptor()
//        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
//
//        let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
//        encoder?.endEncoding()
//        commandBuffer?.present(drawable)
//        commandBuffer?.commit()
//    }
//}
