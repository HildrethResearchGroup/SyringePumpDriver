//
//  ElectrospinnerApp.swift
//  Electrospinner
//
//  Created by Steven DiGregorio on 4/1/22.
//

import SwiftUI

@main
struct SyringePumpDriverApp: App {
    @ObservedObject var syringePump = SyringePump()
    
    var body: some Scene {
        WindowGroup {
            ContentView(electrospinner: electrospinner)
        }
#if os(macOS)
        Settings {
            PreferencesView(electrospinner: electrospinner)
                .frame(width: 400, height: 400, alignment: .top)
        }
#endif
    }
}

// Notes
//Import ORSSerial Package: https://github.com/armadsen/ORSSerialPort.git
//Disable app sandbox
