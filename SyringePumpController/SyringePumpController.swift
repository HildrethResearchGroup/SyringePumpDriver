import Foundation
import Socket

public class SyringePumpController: ObservableObject {
    var communicator: SyringePumpCommunicator?
    
    @Published var nextPortState: String = "Connect"
    @Published var nextPumpState: [pumpNumber: NextPumpState] = [.p0: .startPumping, .p1: .startPumping]
    @Published var units: flowRateUnits = .nL_min
    @Published var flowRate: [pumpNumber: String] = [.p0: "20", .p1: "20"]
    
    //var socket: Socket? = nil
    let address = "192.168.0.7" // Replace with the actual IP address of the syringe pump
    let port: Int32 = 23
    let timeout: TimeInterval = 5.0 // Add a timeout property

    var isConnected: Bool = false // Track connection state

    init() {
        connectToPump()
    }
    
    deinit {
        communicator?.socket.close()
        communicator = nil
    }
    
    private func connectToPump() {
        do {
            communicator = try SyringePumpCommunicator(address: address, port: Int(port), timeout: timeout)
            isConnected = true
            nextPortState = "Disconnect"
            print("Connected to the syringe pump")
        } catch {
            isConnected = false
            print("Failed to connect to the syringe pump: \(error)")
        }
    }
    
    func send(_ sendData: String) {
        let sendString = sendData + "\r\n"
        
        guard let communicator else {
            print("ERROR: send - communicator == nil")
            return
        }
        
        print("Syringe pump controller sent: \(sendString)")
        if let data = sendString.data(using: .utf8) {
            do {
                try communicator.write(data: data)
            } catch {
                print("Failed to send data: \(error)")
            }
        }
    }
    
    enum pumpNumber: String, CaseIterable, Identifiable {
        var id: Self { self }

        case p0 = "Pump 1"
        case p1 = "Pump 2"

        var queryString: String {
            switch self {
            case .p0: return "00"
            case .p1: return "01"
            }
        }
    }
    
    enum flowRateUnits: String, CaseIterable, Identifiable {
        var id: Self { self }

        case mm_hr = "ml / hr"
        case uL_hr = "µl / hr"
        case nL_hr = "nl / hr"
        case mm_min = "ml / min"
        case uL_min = "µl / min"
        case nL_min = "nl / min"

        var queryString: String {
            switch self {
            case .mm_hr: return "MH"
            case .uL_hr: return "UH"
            case .nL_hr: return "NH"
            case .mm_min: return "MM"
            case .uL_min: return "UM"
            case .nL_min: return "NM"
            }
        }
    }

    enum NextPumpState: String {
        case startPumping = "Start Pumping"
        case stopPumping = "Stop Pumping"
    }

    func startOrStopPumping(for pump: pumpNumber) {
        switch nextPumpState[pump]! {
        case .startPumping:
            startPumping(for: pump)
            nextPumpState[pump] = .stopPumping
        case .stopPumping:
            stopPumping(for: pump)
            nextPumpState[pump] = .startPumping
        }
    }
  
    private func startPumping(for pump: pumpNumber) {
        let flowRateValue = flowRate[pump]!
        let unitQueryString = units.queryString
    
        send("") // Sending empty string first seems to make things more consistent
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.send("\(pump.queryString)FUN RAT") // Entering rate mode
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.send("\(pump.queryString)RAT \(flowRateValue) \(unitQueryString)") // Setting new flow rate
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.send("\(pump.queryString)RUN") // Starting pump
        }
    }
    
    private func stopPumping(for pump: pumpNumber) {
        send("\(pump.queryString)STP")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.send("\(pump.queryString)STP") // Stopping pump
        }
    }
    
    func connectOrDisconnect() {
        if isConnected {
            disconnect()
        } else {
            connect()
        }
    }
    
    private func connect() {
        do {
            communicator = try SyringePumpCommunicator(address: address, port: Int(port), timeout: timeout)
            isConnected = true
            nextPortState = "Disconnect"
            print("Connected to the syringe pump")
        } catch {
            print("Failed to connect: \(error)")
            isConnected = false
        }
    }
    
    private func disconnect() {
        communicator?.socket.close() // Close socket
        isConnected = false // Update connection state
        nextPortState = "Connect" // Update nextPortState
        print("Disconnected from the syringe pump")
    }
}
