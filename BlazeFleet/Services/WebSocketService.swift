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
    
    private init() {}
    
    public func connect() {
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
                guard let url = URL(string: wsURLString) else { return }
                
                await MainActor.run {
                    self.startSocket(url: url)
                }
            } catch {
                scheduleReconnect()
            }
        }
    }
    
    public func disconnect() {
        isIntentionalDisconnect = true
        pingTimer?.invalidate()
        pingTimer = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    private func startSocket(url: URL) {
        webSocketTask?.cancel()
        var request = URLRequest(url: url)
        request.setValue("BlazeFleet-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        
        DispatchQueue.main.async {
            self.isConnected = true
            self.reconnectAttempt = 0
        }
        
        startPing()
        receiveMessage()
    }
    
    private func startPing() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true) { [weak self] _ in
            self?.webSocketTask?.sendPing { error in
                if let error = error {
                    print("[WS] Ping error: \(error.localizedDescription)")
                    self?.handleDisconnect()
                }
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
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
                self.receiveMessage()
            case .failure(let error):
                print("[WS] Receive error: \(error.localizedDescription)")
                self.handleDisconnect()
            }
        }
    }
    
    private func handlePayload(_ data: Data) {
        // Try decoding as position or notification envelope
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let type = json["type"] as? String
            
            if type == "notification" {
                if let alert = try? JSONDecoder().decode(NotificationItem.self, from: data) {
                    DispatchQueue.main.async {
                        self.latestAlert = alert
                    }
                }
            } else {
                if let pos = try? JSONDecoder().decode(LivePosition.self, from: data) {
                    DispatchQueue.main.async {
                        self.positions[pos.trackerId] = pos
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
        let delay = min(pow(2.0, Double(reconnectAttempt)), 30.0)
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, !self.isIntentionalDisconnect else { return }
            self.connect()
        }
    }
}
