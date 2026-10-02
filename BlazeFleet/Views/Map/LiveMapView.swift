import SwiftUI
import MapKit

public struct LiveMapView: View {
    @ObservedObject var fleetVM: FleetViewModel
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedVehicle: MobileVehicleSummary?
    @State private var showDetail = false
    
    // Default Dominican Republic center
    private let defaultCoordinate = CLLocationCoordinate2D(latitude: 18.4861, longitude: -69.9312)
    
    public init(fleetVM: FleetViewModel) {
        self.fleetVM = fleetVM
    }
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // MapKit Canvas
                Map(position: $position) {
                    ForEach(fleetVM.vehicles) { vehicle in
                        if let lat = vehicle.lat, let lng = vehicle.lng {
                            Annotation(
                                vehicle.plate,
                                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
                            ) {
                                VehicleAnnotationView(
                                    vehicle: vehicle,
                                    isSelected: selectedVehicle?.id == vehicle.id
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.35)) {
                                        selectedVehicle = vehicle
                                    }
                                }
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .ignoresSafeArea(edges: .top)
                
                // Overlay Controls (Top right)
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Button {
                                fitFleet()
                            } label: {
                                Image(systemName: "viewfinder")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(BlazeTheme.textPrimary)
                                    .frame(width: 40, height: 40)
                                    .background(BlazeTheme.surface.opacity(0.9))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(BlazeTheme.surfaceBorder, lineWidth: 1))
                                    .shadow(radius: 4)
                            }
                            
                            Button {
                                Task { await fleetVM.fetchSummary() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(BlazeTheme.primary)
                                    .frame(width: 40, height: 40)
                                    .background(BlazeTheme.surface.opacity(0.9))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(BlazeTheme.surfaceBorder, lineWidth: 1))
                                    .shadow(radius: 4)
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                    }
                    Spacer()
                }
                
                // Selected Unit Slide-up Card
                if let v = selectedVehicle {
                    VStack(spacing: 0) {
                        HStack {
                            Text(v.plate)
                                .font(.system(size: 14, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(BlazeTheme.surfaceBorder)
                                .cornerRadius(6)
                            
                            Text(v.vehicleModel)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button {
                                withAnimation { selectedVehicle = nil }
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
                            VStack(alignment: .leading, spacing: 4) {
                                Text(v.driverName ?? "Sin conductor asignado")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(BlazeTheme.textSecondary)
                                StatusChip(state: v.state)
                            }
                            
                            Spacer()
                            
                            NavigationLink {
                                VehicleDetailView(vehicle: v)
                            } label: {
                                HStack(spacing: 6) {
                                    Text("Ver detalles")
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
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Mapa en Vivo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            if fleetVM.vehicles.isEmpty {
                await fleetVM.fetchSummary()
            }
            fitFleet()
        }
    }
    
    private func fitFleet() {
        let validCoords = fleetVM.vehicles.compactMap { v -> CLLocationCoordinate2D? in
            guard let lat = v.lat, let lng = v.lng else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        
        if validCoords.isEmpty {
            position = .camera(MapCamera(centerCoordinate: defaultCoordinate, distance: 30000))
            return
        }
        
        let minLat = validCoords.map(\.latitude).min()!
        let maxLat = validCoords.map(\.latitude).max()!
        let minLng = validCoords.map(\.longitude).min()!
        let maxLng = validCoords.map(\.longitude).max()!
        
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLng + maxLng) / 2)
        let span = MKCoordinateSpan(latitudeDelta: max((maxLat - minLat) * 1.4, 0.05), longitudeDelta: max((maxLng - minLng) * 1.4, 0.05))
        
        withAnimation {
            position = .region(MKCoordinateRegion(center: center, span: span))
        }
    }
}
