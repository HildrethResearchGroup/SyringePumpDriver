import Foundation

public class SyringePumpController{
    var communicator: SyringePumpCommunicator
    
    @Published var nextPortState: String = "Connect"
    @Published var nextPumpState: NextPumpState = .startPumping
    @Published var units: flowRateUnits = .nL_min
    @Published var flowRate: String = "20"

    /// Tries to create a controller for an instrument at the given address and port. A timeout value can optionally be specified.
	///
	/// If a timeout value is not specified, a value of `5.0` seconds will be used.
	///
	/// # Example:
	///
	/// The following will try to create a controller for an XPSQ8 instrument at the address `192.168.0.254` and on port number `5001`.
	/// ```
	let communicator = try SyringePumpCommunicator(address: "192.168.0.254", port: 5001)
	/// ```
	/// 
	/// - Parameters:
	///   - address: The IPV4 address of the instrument in dot notation.
	///   - port: The port of the instrument.
	///   - timeout: The maximum time to wait in seconds before timing out when communicating with the instrument.
	public init?(address: String, port: Int, timeout: TimeInterval = 5.0) {
		// TODO: Thrown an error instead of returning nil if the instrument could not be connected to.
		do {
			communicator = try .init(address: address, port: port, timeout: timeout)
		} catch { return nil }
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
