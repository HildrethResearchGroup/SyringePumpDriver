import Foundation
import Socket //import bluesocket library

final class SyringePumpController: ObservableObject {
    
    @Published var nextPortState: String = "Connect"
    @Published var nextPumpState: NextPumpState = .startPumping
    @Published var units: flowRateUnits = .nL_min
    @Published var flowRate: String = "20"
    
    let socket: Socket
    
    /// Tries to create an instance from the specified address, and port of the instrument. A timeout value must also be specified.
        ///
        /// - Parameters:
        ///   - address: The IPV4 address of the instrument in dot notation.
        ///   - port: The port of the instrument.
        ///   - timeout: The maximum time to wait before timing out when communicating with the instrument.
        ///
        /// - Throws: An error if a socket could not be created, connected, or configured properly.
        ///
        init(address: String, port: Int, timeout: TimeInterval) throws {
            // Try to create a socket:
            // - usr-tcp232-302 uses an IPV4 address, so the protocol family .inet is used.
            // - We would like to read to and write from the socket, so .stream is used.
            // - device communicates over .tcp.
            do {
                socket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
            } catch { throw Error.couldNotCreateSocket }
            
            // USr-TCP232-302 sends packets in sizes of 400 bytes
            socket.readBufferSize = 400
            
            do {
                try socket.connect(to: address, port: Int32(port))
            } catch { throw Error.couldNotConnect }
            
            do {
                // Timeout is set as an integer in milliseconds, but it is clearer to pass in a TimeInterval into the function because TimeInterval is used
                // thoughout Foundation to represent time in seconds.
                let timeoutInMilliseconds = UInt(timeout * 1_000.0)
                try socket.setReadTimeout(value: timeoutInMilliseconds)
                try socket.setWriteTimeout(value: timeoutInMilliseconds)
            } catch { throw Error.couldNotSetTimeout }
            
            do {
                // I'm not sure why we need to senable blocking, but the python drivers enabled it, so we will too.
                try socket.setBlocking(mode: true)
            } catch { throw Error.couldNotEnableBlocking }
        }
        
        deinit {
            // Close the connection to the socket because we will no longer need it.
            socket.close()
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

        func send(_ sendString: String) {
                print("Syringe pump controller sent: \(sendString)")
                if let data = sendString.data(using: .utf8) {
                    do {
                        try socket.write(from: data)
                    } catch {
                        print("Failed to send data: \(error)")
                    }
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
    }

extension SyringePumpController {
    /// Reads a message from the instrument.
    ///
    /// - Throws: If a reading or decoding error occurred.
    ///
    /// - Returns: The message string and integer code returned by the instrument.
    func read() throws -> (message: String, code: Int) {
        // The message may not fit in a single buffer (only 1024 bytes). To overcome this, we continue to request data until we are at the end of the message.
        // The API ends all of its messages in the string ",EndOfAPI", so we continue to append values to `string` until it ends in ",EndOfAPI".
        var string = ""
        repeat {
            do {
                guard let substring = try socket.readString() else { throw Error.failedReadOperation }
                string += substring
            } catch { throw Error.failedReadOperation }
        } while !string.hasSuffix(",EndOfAPI")
        
        // The message returned is divided into three parts seperated by commas:
        // 1. The integer code associated with the message
        // 2. The string content of the message
        // 3. The string "EndOfAPI" to indicate the end of the message
        //
        // We can discard the "EndOfAPI" portion because every message ends with this, so it carries no information.
        // We then want to seperate the integer code and string content to return to the user.
        // The firstDividerIndex is the string index of the first comma, which seperates the integer code and string content.
        guard let firstDividerIndex = string.firstIndex(of: ",") else { throw Error.couldNotDecode }
        
        // integerCodeRange is the range of characters of the integer code. It is from the first character to immediately before the first comma.
        let integerCodeRange = string.startIndex..<firstDividerIndex
        guard let integerCode = Int(string[integerCodeRange]) else { throw Error.couldNotDecode }
        
        // messageRange is the range of characters of the string content. It is from after the first comma to immediately before the comma directly before
        // the substring "EndOfAPI". Because there will always be 9 final characters we want to cut from the end (",EndOfAPI"), we can simply subtract 9 from
        // the string's end index to get the end index.
        let messageRange = string.index(after: firstDividerIndex)..<string.index(string.endIndex, offsetBy: -9)
        let message = String(string[messageRange])
        
        return (message, integerCode)
    }
}

// MARK: Writing

extension SyringePumpController {
    /// Sends a string to the instrument. This should be a function such as `"ElapsedTimeGet(double *)"`.
    /// - Parameter string: The string to sent the instrument.
    func write(string: String) throws {
        do {
            try socket.write(from: string)
        } catch {
            throw Error.failedWriteOperation
        }
    }
}

// MARK: Error

//update these errors so they correspond with the errors from the pump
extension SyringePumpController {
    /// An error associated with an XPSQ8Communicator.
    ///
    /// - `couldNotCreateSocket`: The socket to communicate with the instrument could not be created.
    /// - `couldNotConnect`: The instrument could not be connected to. The instrument may not be connected, or could have a different address/port than the one specified.
    /// - `couldNotSetTimeout`: The timeout value could not be set.
    /// - `couldNotEnableBlocking`: The socket was unable to enable blocking.
    enum Error: Swift.Error {
        case couldNotCreateSocket
        case couldNotConnect
        case couldNotSetTimeout
        case couldNotEnableBlocking
        case failedWriteOperation
        case failedReadOperation
        case couldNotDecode
    }
}

// MARK: Error Descriptions
extension SyringePumpController.Error {
    var localizedDescription: String {
        switch self {
        case .couldNotConnect:
            return "Could not connect."
        case .couldNotCreateSocket:
            return "Could not create socket."
        case .couldNotSetTimeout:
            return "Could not set timeout."
        case .couldNotEnableBlocking:
            return "Could not enable blocking."
        case .failedWriteOperation:
            return "Failed write operation."
        case .failedReadOperation:
            return "Failed read operation."
        case .couldNotDecode:
            return "Could not decode."
        }
    }
}
