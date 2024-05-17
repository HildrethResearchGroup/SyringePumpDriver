//  SyringePumpController.swift
//  Syringe Pump Driver
//  Starter code to control syringe pump

import Foundation
import ORSSerial

class SyringePumpController: ObservableObject {
    // MARK: - Serial Port Methods
    var serialPortManager: ORSSerialPortManager = ORSSerialPortManager.shared()
    @Published var serialPort: ORSSerialPort? {
        didSet {
            serialPort?.numberOfStopBits = 1
            serialPort?.parity = .none
            serialPort?.baudRate = 19200
            serialPort?.shouldEchoReceivedData = true
        }
    }
    @Published var nextPortState = "Open"
    
    func openOrClosePort() {
        if let port = self.serialPort {
            if (port.isOpen) {
                port.close()
                nextPortState = "Open"
            } else {
                port.open()
                nextPortState = "Close"
            }
        }
    }
    
    func send(_ sendData :String) {

        let sendString = sendData + "\r\n" // adding line end characters for syringe pump to work
        print("Syringe pump controller sent:\(sendString)")
        if let data = sendString.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
    }
    
    // MARK: - Syringe Pump Controller Methods
    @Published var nextPumpState: NextPumpState = .startPumping
    @Published var units: flowRateUnits = .nL_min
    @Published var flowRate: String = "20"
    
    enum flowRateUnits: String, CaseIterable, Identifiable {
        var id: Self {self}
        
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
        self.send("") // Sending empty string first seems to make things more consistant
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
}

extension ORSSerialPort: Identifiable {
    public var id: ORSSerialPort {return self}
}
