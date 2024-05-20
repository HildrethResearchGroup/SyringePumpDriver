import Foundation
import Socket //import bluesocket library

class SyringePumpController: ObservableObject {
    var socket: Socket? = nil
    let address = "192.168.1.100" // Replace with the actual IP address of the syringe pump
    let port: Int32 = 12345 // Replace with the actual port of the syringe pump
    
    @Published var nextPortState: String = "Connect"
    @Published var nextPumpState: NextPumpState = .startPumping
    @Published var units: flowRateUnits = .nL_min
    @Published var flowRate: String = "20"
    
    var isConnected: Bool = false // Track connection state

    init() {
        connectToPump()
    }

    deinit {
        socket?.close()
    }

    private func connectToPump() {
        do {
            socket = try Socket.create()
            try socket?.connect(to: address, port: port)
            print("Connected to the syringe pump")
        } catch {
            print("Failed to connect to the syringe pump: \(error)")
        }
    }

    func send(_ sendString: String) {
        print("Syringe pump controller sent: \(sendString)")
        if let data = sendString.data(using: .utf8) {
            do {
                try socket?.write(from: data)
            } catch {
                print("Failed to send data: \(error)")
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

    func startOrStopPumping() {
        switch nextPumpState {
        case .startPumping:
            startPumping()
            nextPumpState = .stopPumping
        case .stopPumping:
            stopPumping()
            nextPumpState = .startPumping
        }
    }

    private func startPumping() {
        self.send("") // Sending empty string first seems to make things more consistent
        // Adding delays for serial communication to work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.send("FUN RAT") // entering rate mode
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.send("RAT \(self.flowRate) \(self.units.queryString)") // Setting new flow rate
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.send("RUN") // starting pump
        }
    }

    private func stopPumping() {
        send("STP")
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
            socket = try Socket.create() // Create socket
            try socket?.connect(to: address, port: port) // Connect to address and port
            isConnected = true // Update connection state
            nextPortState = "Disconnect" // Update nextPortState
            print("Connected to the syringe pump")
        } catch {
            print("Failed to connect to the syringe pump: \(error)")
        }
    }

    private func disconnect() {
        socket?.close() // Close socket
        isConnected = false // Update connection state
        nextPortState = "Connect" // Update nextPortState
        print("Disconnected from the syringe pump")
    }
}
