import SwiftUI

struct CustomVerticalDivider: View {
    let width: CGFloat
    let height: CGFloat
    let color: Color
    
    init(width: CGFloat = 1, height: CGFloat = 20, color: Color = .gray) {
        self.width = width
        self.height = height
        self.color = color
    }
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: width, height: height)
    }
}

struct SyringePumpView: View {
    @ObservedObject var controller: SyringePumpController


    var body: some View {
        var enable1: Bool = false
        var enable2: Bool = false
        Text("Syringe Pump Network").font(.title2).padding(.top, +30)
        HStack {
            Text("Port") // Bluesocket doesn't require port selection
            Button(action: { controller.connectOrDisconnect() }) {
                Text(controller.nextPortState) // Display the current port state
            }
            
            Toggle(isOn: Binding(
                get: { self.controller.nextPumpState == .stopPumping1 },
                set: { _ in
                    switch (enable1, enable2){
                    case (true,false):
                        self.controller.startOrStopPumping1(pump: "00")
                    case (true,true):
                        self.controller.startOrStopPumping1(pump: "00")
                        self.controller.startOrStopPumping2(pump: "01")
                    case (false,true):
                        self.controller.startOrStopPumping2(pump: "01")
                    default:
                        break
                    }
                }
            )) {
                Text(self.controller.nextPumpState == .startPumping1 ? "Start Both Pumps" : "Stop Both Pumps")
            }
            .toggleStyle(SwitchToggleStyle(tint: .blue)) // Apply SwitchToggleStyle
        }
        

        
        
        HStack{
        
            VStack {
                Text("Syringe Pump 1").font(.title2).padding(.top, -5)
                Form {
                    // Select units
                    HStack {
                        TextField("Flow Rate", text: $controller.flowRate)
                    }
                    Picker("Units", selection: $controller.units) {
                        ForEach(SyringePumpController.flowRateUnits.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    Toggle(isOn: Binding(
                        get: { self.controller.nextPumpState == .stopPumping1 },
                        set: { _ in
                            self.controller.startOrStopPumping1(pump: "00")
                        }
                    )) {
                        Text(self.controller.nextPumpState == .startPumping1 ? "Start Pumping 1" : "Stop Pumping 1")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue)) // Apply SwitchToggleStyle
                    
                    
                    Toggle(isOn: Binding(
                        get: { enable1},
                        set: { _ in
                            switch (enable1){
                            case true:
                                enable1 = false
                            case false:
                                enable1 = true
                            }
                        }
                    )) {
                        Text("Enable Pump 1")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue)) // Apply SwitchToggleStyle
                }
            }
            //CustomDivider(height: 30, color: .gray)
            CustomVerticalDivider(width: 1, height: 140, color: .gray)
            //Divider()
            VStack {
                Text("Syringe Pump 2").font(.title2).padding(.top, -5)
                Form {
                    // Select units
                    HStack {
                        TextField("Flow Rate", text: $controller.flowRate2)
                    }
                    Picker("Units", selection: $controller.units2) {
                        ForEach(SyringePumpController.flowRateUnits2.allCases) { unit2 in
                            Text(unit2.rawValue).tag(unit2)
                        }
                    }
                    Toggle(isOn: Binding(
                        get: { self.controller.nextPumpState2 == .stopPumping2 },
                        set: { _ in
                            self.controller.startOrStopPumping2(pump: "01")
                        }
                    )) {
                        Text(self.controller.nextPumpState2 == .startPumping2 ? "Start Pumping 2" : "Stop Pumping 2")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue)) // Apply SwitchToggleStyle
                    
                    
                    Toggle(isOn: Binding(
                        get: { enable2 },
                        set: { _ in
                            switch (enable2){
                            case true:
                                enable2 = false
                            case false:
                                enable2 = true
                            }                        }
                    )) {
                        Text("Enable Pump 2")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue)) // Apply SwitchToggleStyle
                }
            }
        }
    }
}

struct SyringePumpView_Previews: PreviewProvider {
    static var previews: some View {
        SyringePumpView(controller: SyringePumpController())
    }
}
