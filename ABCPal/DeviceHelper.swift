//
//  DeviceHelper.swift
//  ABCPal
//
//  Helper utilities for device detection
//

import UIKit

struct DeviceHelper {
    // Check if device is a small screen (iPhone 8, SE, and similar)
    static var isSmallScreen: Bool {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let smallerDimension = min(screenWidth, screenHeight)
        
        // iPhone 8, 7, 6s, 6, SE (2nd/3rd gen) have width of 375
        // iPhone SE (1st gen), 5s, 5 have width of 320
        // We'll consider anything with smaller dimension <= 375 as small
        return smallerDimension <= 375
    }
    
    // Check if landscape orientation should be allowed
    static var shouldAllowLandscape: Bool {
        // Block landscape on small screens
        return !isSmallScreen
    }
    
    // Get device model name for debugging
    static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String(validatingUTF8: ptr)
            }
        }
        return modelCode ?? "Unknown"
    }
}