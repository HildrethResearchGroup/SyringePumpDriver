import Foundation
import Socket

public class ManualSyringePumpController: ObservableObject {
    var communicator: ManualSyringePumpCommunicator?
    
    @Published var nextPortState: String = "Connect"
    var nextPumpState: NextPumpState = .startPumping1
    var nextPumpState2: NextPumpState2 = .startPumping2
    
    @Published var id1: String = "10"
    @Published var id2: String = "10"
    
    @Published var units: flowRateUnits = .nL_min
    @Published var units2: flowRateUnits2 = .nL_min
    
    @Published var pumpNum: pumpNumber = .p0
    
    @Published var flowRate: String = "20"
    @Published var flowRate2: String = "20"
    
    @Published var pump: String = "00"
    @Published var dualStart: Bool = false
    @Published var subString: String = ""
    
    
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
            communicator = try ManualSyringePumpCommunicator(address: address, port: Int(port), timeout: timeout)
            isConnected = true
            nextPortState = "Disconnect"
            print("Connected to the syringe pump")
        } catch {
            isConnected = false
            print("Failed to connect to the syringe pump: \(error)")
        }
    }
    func getVol() throws -> String{
        return subString
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
    enum flowRateUnits2: String, CaseIterable, Identifiable {
        var id: Self { self }
        
        case mm_hr = "ml / hr"
        case uL_hr = "µl / hr"
        case nL_hr = "nl / hr"
        case mm_min = "ml / min"
        case uL_min = "µl / min"
        case nL_min = "nl / min"
        
        var queryString2: String {
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
    /*
     enum NextPumpState: String {
     case startPumping = "Start Pumping"
     case stopPumping = "Stop Pumping"
     }*/
    enum NextPumpState: String {
        case startPumping1 = "Start Pumping 1"
        case stopPumping1 = "Stop Pumping 1"
    }
    
    
    enum NextPumpState2: String {
        case startPumping2 = "Start Pumping 2"
        case stopPumping2 = "Stop Pumping 2"
    }
    
    func startOrStopPumping1(pump: String) {
        switch nextPumpState {
        case .startPumping1:
            startPumping(pump: pump)
            nextPumpState = .stopPumping1
        case .stopPumping1:
            stopPumping(pump: pump)
            nextPumpState = .startPumping1
        }
    }
    
    func startOrStopPumping2(pump: String) {
        switch nextPumpState2 {
        case .startPumping2:
            startPumping(pump: pump)
            nextPumpState2 = .stopPumping2
        case .stopPumping2:
            stopPumping(pump: pump)
            nextPumpState2 = .startPumping2
        }
    }
    
    
    func dualChange(){
        if dualStart == true{
            dualStart = false
        }
        else{
            dualStart = true
        }
    }
    
    
    private func startPumping(pump: String) {
        switch (pump){
        case "00":
            self.send("") // Sending empty string first seems to make things more consistent
            // Adding delays for serial communication to work
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.send("\(pump)DIA \(self.id1)") // entering rate mode
            }

            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.send("\(pump)FUN RAT") // entering rate mode
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.send("\(pump)RAT \(self.flowRate) \(self.units.queryString)") // Setting new flow rate
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.send("\(pump)RUN") // starting pump
            }
        case "01":
            self.send("") // Sending empty string first seems to make things more consistent
            // Adding delays for serial communication to work
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.send("\(pump)DIA \(self.id2)") // entering rate mode
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.send("\(pump)FUN RAT") // entering rate mode
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.send("\(pump)RAT \(self.flowRate2) \(self.units2.queryString2)") // Setting new flow rate
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.send("\(pump)RUN") // starting pump
            }
        default:
            break
        }
    }
    
    private func stopPumping(pump: String) {
        send("\(pump)STP")


        var data = Data()
        do{
            try self.readAndPrint(socket: self.communicator!.socket, data: &data)
        }catch{
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.send("\(pump)STP") // entering rate mode
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
            communicator = try ManualSyringePumpCommunicator(address: address, port: Int(port), timeout: timeout)
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
    
    
    func readAndPrint(socket: Socket, data: inout Data) throws -> String? {
        self.send("CLD")
        
        Thread.sleep(forTimeInterval: 0.5)
        
        self.send("01DIS")
        
        
        Thread.sleep(forTimeInterval: 0.5)
        
        data.count = 0
        let    bytesRead = try socket.read(into: &data)
        if bytesRead > 0 {
            //print("Read \(bytesRead) from socket...")
            guard let response = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) else {
                print("Error accessing received data...")
                return nil
            }
            if let utf8String = String(data: data, encoding: .utf8) {
                // Successfully converted Data to a UTF-8 String
                //print("New thing: \(utf8String)")
            } else {
                // Conversion failed
                print("Failed to convert data to UTF-8 string")
            }
            //            print("Response: \(response)")
            let inputString = response as String
            //            let startIndex = 41
            //            let endIndex = 46
            //            let startStringIndex = inputString.index(inputString.startIndex, offsetBy: startIndex)
            //            let endStringIndex = inputString.index(inputString.startIndex, offsetBy: endIndex)
            //            // Extract the substring between the specified indices
            //            let substring = inputString[startStringIndex..<endStringIndex]
            //            print("Volume Dispensed \(substring) mL")
            //            return String(describing: response)
            
            
            
            if let secondIRange = rangeOfNthOccurrence(of: "I", in: inputString, occurrence: 2) {
                // Find the range of "W" after the second "I"
                if let rangeOfW = inputString.range(of: "W", range: secondIRange.upperBound..<inputString.endIndex) {
                    // Extract the substring between the second "I" and the "W"
                    let substring = inputString[secondIRange.upperBound..<rangeOfW.lowerBound]
                    
                    print("Volume Dispensed: \(substring) mL")
                } else {
                    print("Could not find 'W' in the string after the second 'I'")
                }
            } else {
                print("Could not find the second 'I' in the string")
            }
        }
        return nil
    }
    
    
    
    func rangeOfNthOccurrence(of searchString: String, in inputString: String, occurrence: Int) -> Range<String.Index>? {
        var currentIndex = inputString.startIndex
        var count = 0
        
        while let range = inputString.range(of: searchString, range: currentIndex..<inputString.endIndex) {
            count += 1
            if count == occurrence {
                return range
            }
            currentIndex = range.upperBound
        }
        return nil
    }
    
    
}
