import Foundation
import Combine

public final class WebSocketService: ObservableObject {
    public static let shared = WebSocketService()
    
    @Published public var isConnected = false
    @Published public var positions: [String: LivePosition] = [:]
    @Published public var latestAlert: NotificationItem?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    private var pingTimer: Timer?
    private var reconnectAttempt = 0
    private var isIntentionalDisconnect = false
    
    private var isConnecting = false
    
    private init() {}
    
    public func connect() {
        guard !isConnected && !isConnecting else { return }
        isConnecting = true
        isIntentionalDisconnect = false
        Task {
            do {
                let ticketResp = try await APIClient.shared.getWSTicket()
                let baseURL = APIClient.shared.baseURL
                let wsBase = baseURL.replacingOccurrences(of: "http://", with: "ws://")
                                    .replacingOccurrences(of: "https://", with: "wss://")
                let wsURLString: String
                if ticketResp.url.starts(with: "ws://") || ticketResp.url.starts(with: "wss://") {
                    wsURLString = ticketResp.url
                } else if ticketResp.url.starts(with: "/") {
                    wsURLString = "\(wsBase)\(ticketResp.url)"
                } else {
                    wsURLString = "\(wsBase)/\(ticketResp.url)"
                }
                guard let url = URL(string: wsURLString) else {
                    self.isConnecting = false
                    return
                }
                
                await MainActor.run {
                    self.isConnecting = false
                    self.startSocket(url: url)
                }
            } catch {
                self.isConnecting = false
                scheduleReconnect()
            }
        }
    }
    
    public func disconnect() {
        isIntentionalDisconnect = true
        isConnecting = false
        pingTimer?.invalidate()
        pingTimer = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    private func startSocket(url: URL) {
        if let old = webSocketTask {
            old.cancel(with: .normalClosure, reason: nil)
        }
        var request = URLRequest(url: url)
        request.setValue("BlazeFleet-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        let newTask = session.webSocketTask(with: request)
        self.webSocketTask = newTask
        newTask.resume()
        
        DispatchQueue.main.async {
            self.isConnected = true
            self.reconnectAttempt = 0
        }
        
        startPing()
        receiveMessage(for: newTask)
    }
    
    public func reconnectNow() {
        guard !isConnected else { return }
        isConnecting = false
        reconnectAttempt = 0
        connect()
    }
    
    private func startPing() {
        pingTimer?.invalidate()
        let timer = Timer(timeInterval: 20.0, repeats: true) { [weak self] _ in
            self?.webSocketTask?.sendPing { error in
                if let error = error {
                    print("[WS] Ping error: \(error.localizedDescription)")
                    self?.handleDisconnect()
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        pingTimer = timer
    }
    
    private func receiveMessage(for task: URLSessionWebSocketTask) {
        task.receive { [weak self, weak task] result in
            guard let self = self, let task = task, task == self.webSocketTask else { return }
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self.handlePayload(data)
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        self.handlePayload(data)
                    }
                @unknown default:
                    break
                }
                self.receiveMessage(for: task)
            case .failure(let error):
                let nsError = error as NSError
                if nsError.code == NSURLErrorCancelled || nsError.code == -999 {
                    return
                }
                print("[WS] Receive error: \(error.localizedDescription)")
                self.handleDisconnect()
            }
        }
    }
    
    private func handlePayload(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        let type = json["type"] as? String
        
        // Ignore initial websocket connected acknowledgement
        if type == "connected" {
            return
        }
        
        if type == "notification" || json["kind"] != nil {
            if let alert = try? JSONDecoder().decode(NotificationItem.self, from: data) {
                DispatchQueue.main.async {
                    self.latestAlert = alert
                }
            }
        } else {
            let decodedPos: LivePosition?
            if let pos = try? JSONDecoder().decode(LivePosition.self, from: data) {
                decodedPos = pos
            } else if let nested = json["data"] as? [String: Any],
                      let nestedData = try? JSONSerialization.data(withJSONObject: nested),
                      let pos = try? JSONDecoder().decode(LivePosition.self, from: nestedData) {
                decodedPos = pos
            } else {
                decodedPos = nil
            }
            
            if let pos = decodedPos {
                DispatchQueue.main.async {
                    self.positions[pos.trackerId] = pos
                    if let vId = pos.vehicleId, !vId.isEmpty {
                        self.positions[vId] = pos
                    }
                }
            }
        }
    }
    
    private func handleDisconnect() {
        DispatchQueue.main.async {
            self.isConnected = false
        }
        pingTimer?.invalidate()
        pingTimer = nil
        if !isIntentionalDisconnect {
            scheduleReconnect()
        }
    }
    
    private func scheduleReconnect() {
        reconnectAttempt += 1
        let delay = min(2.0 * Double(reconnectAttempt), 10.0)
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, !self.isIntentionalDisconnect else { return }
            self.connect()
        }
    }
}
