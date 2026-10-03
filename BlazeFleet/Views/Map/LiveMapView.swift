import SwiftUI
import MapKit

public enum FleetMapStyle: String, CaseIterable, Identifiable {
    case standard = "Estándar"
    case satellite = "Satélite"
    case hybrid = "Híbrido"
    
    public var id: String { rawValue }
}

public struct LiveMapView: View {
    @ObservedObject var fleetVM: FleetViewModel
    @ObservedObject var wsService = WebSocketService.shared
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedVehicleId: String?
    @State private var selectedMapStyle: FleetMapStyle = .standard
    @State private var showTraffic = false
    
    // Default Dominican Republic center (Santiago / Cibao)
    private let defaultCoordinate = CLLocationCoordinate2D(latitude: 19.4517, longitude: -70.6970)
    
    public init(fleetVM: FleetViewModel) {
        self.fleetVM = fleetVM
    }
    
    private var selectedVehicle: MobileVehicleSummary? {
        guard let id = selectedVehicleId else { return nil }
        return fleetVM.vehicles.first { $0.id == id || $0.trackerId == id || $0.vehicleId == id }
    }
    
    private var anyVehicleMoving: Bool {
        fleetVM.vehicles.contains { $0.state == .moving }
    }
    
    private var activeMapStyle: MapStyle {
        switch selectedMapStyle {
        case .standard:
            return .standard(elevation: .realistic, pointsOfInterest: .all, showsTraffic: showTraffic)
        case .satellite:
            return .imagery(elevation: .realistic)
        case .hybrid:
            return .hybrid(elevation: .realistic, pointsOfInterest: .all, showsTraffic: showTraffic)
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // MapKit Canvas
                Map(position: $position) {
                    ForEach(fleetVM.vehicles) { vehicle in
                        if let lat = vehicle.lat, let lng = vehicle.lng {
                            Annotation(
                                "",
                                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
                            ) {
                                VehicleAnnotationView(
                                    vehicle: vehicle,
                                    isSelected: selectedVehicleId == vehicle.id || selectedVehicleId == vehicle.trackerId || selectedVehicleId == vehicle.vehicleId
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.35)) {
                                        selectedVehicleId = vehicle.id
                                        position = .camera(MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng), distance: 2500))
                                    }
                                }
                            }
                        }
                    }
                }
                .mapStyle(activeMapStyle)
                .ignoresSafeArea(edges: .top)
                
                // Top Floating Status Banner
                VStack {
                    HStack {
                        Button {
                            wsService.reconnectNow()
                            Task { await fleetVM.fetchSummary() }
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(wsService.isConnected ? BlazeTheme.moving : BlazeTheme.idle)
                                    .frame(width: 8, height: 8)
                                
                                Text("\(fleetVM.vehicles.count) unidades")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(BlazeTheme.textPrimary)
                                
                                Text("•")
                                    .foregroundColor(BlazeTheme.textMuted)
                                
                                Text(wsService.isConnected ? "En vivo" : "Sincronizando...")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(wsService.isConnected ? BlazeTheme.moving : BlazeTheme.idle)
                                
                                if !wsService.isConnected {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(BlazeTheme.idle)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(BlazeTheme.surface.opacity(0.92))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(BlazeTheme.surfaceBorder, lineWidth: 1))
                            .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    Spacer()
                }
                
                // Overlay Controls (Top right)
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            // Layer / Map Style Menu
                            Menu {
                                Picker("Capa del Mapa", selection: $selectedMapStyle) {
                                    ForEach(FleetMapStyle.allCases) { style in
                                        Text(style.rawValue).tag(style)
                                    }
                                }
                                
                                Divider()
                                
                                Toggle(isOn: $showTraffic) {
                                    Label("Tráfico en Vivo", systemImage: "car.2.fill")
                                }
                            } label: {
                                Image(systemName: "square.3.layers.3d")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(selectedMapStyle != .standard || showTraffic ? BlazeTheme.primary : BlazeTheme.textPrimary)
                                    .frame(width: 42, height: 42)
                                    .background(BlazeTheme.surface.opacity(0.92))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(BlazeTheme.surfaceBorder, lineWidth: 1))
                                    .shadow(color: .black.opacity(0.25), radius: 4)
                            }
                            
                            // Fit Fleet / Center Viewfinder
                            Button {
                                fitFleet()
                            } label: {
                                Image(systemName: "viewfinder")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(BlazeTheme.textPrimary)
                                    .frame(width: 42, height: 42)
                                    .background(BlazeTheme.surface.opacity(0.92))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(BlazeTheme.surfaceBorder, lineWidth: 1))
                                    .shadow(color: .black.opacity(0.25), radius: 4)
                            }
                            
                            // Manual Refresh
                            Button {
                                Task { await fleetVM.fetchSummary() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(BlazeTheme.primary)
                                    .frame(width: 42, height: 42)
                                    .background(BlazeTheme.surface.opacity(0.92))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(BlazeTheme.surfaceBorder, lineWidth: 1))
                                    .shadow(color: .black.opacity(0.25), radius: 4)
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 12)
                    }
                    Spacer()
                }
                
                // Selected Unit Slide-up Card
                if let v = selectedVehicle {
                    VStack(spacing: 0) {
                        HStack(alignment: .center) {
                            Text(v.plate)
                                .font(.system(size: 14, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(BlazeTheme.surfaceBorder)
                                .cornerRadius(6)
                            
                            Text(v.vehicleModel.isEmpty ? "Vehículo" : v.vehicleModel)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button {
                                withAnimation { selectedVehicleId = nil }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(BlazeTheme.textMuted)
                                    .font(.system(size: 20))
                            }
                        }
                        
                        Divider()
                            .background(BlazeTheme.surfaceBorder)
                            .padding(.vertical, 10)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 5) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(BlazeTheme.primary)
                                    Text(v.driverName ?? "Sin conductor asignado")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(BlazeTheme.textSecondary)
                                }
                                
                                HStack(spacing: 8) {
                                    StatusChip(state: v.state)
                                    
                                    // Prominent Speed Badge
                                    if let speed = v.speedKmh, v.state == .moving || speed > 0 {
                                        HStack(spacing: 4) {
                                            Image(systemName: "speedometer")
                                                .font(.system(size: 11, weight: .bold))
                                            Text("\(Int(speed.rounded())) km/h")
                                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        }
                                        .foregroundColor(BlazeTheme.moving)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(BlazeTheme.moving.opacity(0.18))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(BlazeTheme.moving.opacity(0.35), lineWidth: 1)
                                        )
                                    } else if v.state == .stopped {
                                        HStack(spacing: 3) {
                                            Image(systemName: "speedometer")
                                                .font(.system(size: 10))
                                            Text("0 km/h")
                                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        }
                                        .foregroundColor(BlazeTheme.textMuted)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2.5)
                                        .background(BlazeTheme.surfaceBorder.opacity(0.4))
                                        .cornerRadius(5)
                                    }
                                    
                                    if let odo = v.vehicleOdometerKm, odo > 0 {
                                        Text("\(odo) km")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(BlazeTheme.textMuted)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            NavigationLink {
                                VehicleDetailView(vehicle: v)
                            } label: {
                                HStack(spacing: 6) {
                                    Text("Detalles")
                                        .font(.system(size: 13, weight: .bold))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(BlazeTheme.primary)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(16)
                    .background(BlazeTheme.surface.opacity(0.96))
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(BlazeTheme.primaryGlow, lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            if fleetVM.vehicles.isEmpty {
                await fleetVM.fetchSummary()
            }
            if !wsService.isConnected {
                wsService.reconnectNow()
            }
            fitFleet()
            
            // Continuous fast adaptive sync while LiveMapView is active
            while !Task.isCancelled {
                let delay: UInt64 = (!wsService.isConnected || anyVehicleMoving) ? 4_000_000_000 : 12_000_000_000
                try? await Task.sleep(nanoseconds: delay)
                guard !Task.isCancelled else { break }
                await fleetVM.fetchSummary()
                if !wsService.isConnected {
                    wsService.reconnectNow()
                }
            }
        }
    }
    
    private func fitFleet() {
        let validCoords = fleetVM.vehicles.compactMap { v -> CLLocationCoordinate2D? in
            guard let lat = v.lat, let lng = v.lng else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        
        if validCoords.isEmpty {
            position = .camera(MapCamera(centerCoordinate: defaultCoordinate, distance: 35000))
            return
        }
        
        let minLat = validCoords.map(\.latitude).min()!
        let maxLat = validCoords.map(\.latitude).max()!
        let minLng = validCoords.map(\.longitude).min()!
        let maxLng = validCoords.map(\.longitude).max()!
        
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLng + maxLng) / 2)
        let latDelta = max((maxLat - minLat) * 1.5, 0.04)
        let lngDelta = max((maxLng - minLng) * 1.5, 0.04)
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        
        withAnimation(.easeInOut(duration: 0.8)) {
            position = .region(MKCoordinateRegion(center: center, span: span))
        }
    }
}
