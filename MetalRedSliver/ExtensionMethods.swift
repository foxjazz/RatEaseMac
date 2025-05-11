//
//  ExtensionMethods.swift
//  MetalRedSliver
//
//  Created by Joe Dickinson on 11/05/2025.
//
import Foundation

extension Array where Element: Equatable {
    mutating func appendUnique(_ item: Element) {
        if !self.contains(item) {
            self.append(item)
        }
    }
}
