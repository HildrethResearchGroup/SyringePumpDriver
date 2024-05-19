//
//  ContentView.swift
//  Electrospinner
//
//  Created by Steven DiGregorio on 4/1/22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var electrospinner: Electrospinner
    
    var body: some View {
        HSplitView {
            SelectableCameraView().padding()
            VStack {
                GeneralParameterView(electrospinner: electrospinner).padding()
                Divider()
                SyringePumpView(controller: electrospinner.syringePump).padding()
                Divider()
                VoltageSupplyView(controller: electrospinner.voltageSupply).padding()
                Divider()
                ElectrospinnerView(electrospinner: electrospinner).padding()
            }.frame(minWidth: 100, idealWidth: 200, maxWidth: 300, minHeight: 400, idealHeight: 800, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
