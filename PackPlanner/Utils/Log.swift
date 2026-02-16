//
//  Log.swift
//  PackPlanner
//
//  Centralized logging using os.Logger
//

import Foundation
import os

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.packplanner"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let coreData = Logger(subsystem: subsystem, category: "coreData")
    static let cloudKit = Logger(subsystem: subsystem, category: "cloudKit")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
