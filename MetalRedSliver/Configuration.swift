//
//  Configuration.swift
//  MetalRedSliver
//
//  Created by Joe Dickinson on 12/05/2025.
//
import Foundation
struct AppConfig: Codable {
    var selectedTitle: String
    var rectLeft: Int
    var rectTop: Int
    var rectWidth: Int
    var rectHeight: Int
}
func configFileURL() -> URL {
    let manager = FileManager.default
    let url = try! manager.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    ).appendingPathComponent("config.json")
    
    return url
}
