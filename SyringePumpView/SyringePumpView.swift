import SwiftUI

struct SyringePumpView: View {
    @ObservedObject var controller: SyringePumpController

    var body: some View {
        VStack {
            Text("Syringe Pump").font(.title2).padding(.top, -5)
            Form {
                // Select Port
                HStack {
                    Text("Port") // Bluesocket doesn't require port selection
                    Button(action: { controller.connectOrDisconnect() }) {
                        Text(controller.nextPortState) // Display the current port state
                    }
                }

                // Select units
                HStack {
                    TextField("Flow Rate", text: $controller.flowRate)
                }

                Picker("Units", selection: $controller.units) {
                    ForEach(SyringePumpController.flowRateUnits.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }

                // Start Button
                Button(action: { controller.startOrStopPumping() }) {
                    Text(controller.nextPumpState.rawValue) // Display the current pump state
                }
                
                Button("RUN", action: controller.runPump)
            }
        }
    }
}

struct SyringePumpView_Previews: PreviewProvider {
    static var previews: some View {
        SyringePumpView(controller: SyringePumpController())
    }
}
