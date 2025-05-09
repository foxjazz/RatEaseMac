//
//  Item.swift
//  MetalRedSliver
//
//  Created by Joe Dickinson on 09/05/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
