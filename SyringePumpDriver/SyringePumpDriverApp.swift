//
//  ElectrospinnerApp.swift
//  Electrospinner
//
//  Created by Steven DiGregorio on 4/1/22.
//

import SwiftUI

@main
struct SyringePumpDriverApp: App {
    @StateObject private var controller = SyringePumpController() // Create a shared instance of the controller

    var body: some Scene {
        WindowGroup {
            SyringePumpView(controller: controller)
        }
#if os(macOS)
        Settings {
            PreferencesView(controller: controller)
                .frame(width: 400, height: 400, alignment: .top)
        }
#endif
    }
}

// Notes
//Import ORSSerial Package: https://github.com/armadsen/ORSSerialPort.git
//Disable app sandbox
