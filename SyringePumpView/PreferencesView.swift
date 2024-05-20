//
//  PreferencesView.swift
//  SyringePumpDriver
//
//  Created by Steve on 5/20/24.
//

import SwiftUI

struct PreferencesView: View {
    @ObservedObject var controller: SyringePumpController

    var body: some View {
        VStack {
            Text("Preferences")
                .font(.largeTitle)
            // Add your settings UI here
        }
        .padding()
    }
}
