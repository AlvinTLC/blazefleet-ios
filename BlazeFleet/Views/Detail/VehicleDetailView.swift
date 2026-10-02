import SwiftUI
import MapKit

public struct VehicleDetailView: View {
    @StateObject private var detailVM: VehicleDetailViewModel
    @State private var showCommandModal = false
    
    public init(vehicle: MobileVehicleSummary) {
        _detailVM = StateObject(wrappedValue: VehicleDetailViewModel(vehicle: vehicle))
    }
    
    public var body: some View {
        ZStack {
            BlazeTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Feedback Toasts
                    if let success = detailVM.commandSuccessMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(BlazeTheme.moving)
                            Text(success)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(BlazeTheme.textPrimary)
                            Spacer()
                        }
                        .padding()
                        .background(BlazeTheme.moving.opacity(0.15))
                        .cornerRadius(12)
                    }
                    
                    if let error = detailVM.commandErrorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(BlazeTheme.danger)
                            Text(error)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(BlazeTheme.textPrimary)
                            Spacer()
                        }
                        .padding()
                        .background(BlazeTheme.danger.opacity(0.15))
                        .cornerRadius(12)
                    }
                    
                    // Vehicle Header Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(detailVM.vehicle.plate)
                                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(BlazeTheme.surfaceBorder)
                                .cornerRadius(8)
                            
                            Spacer()
                            
                            StatusChip(state: detailVM.vehicle.state)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(detailVM.vehicle.vehicleModel)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
                            if let driver = detailVM.vehicle.driverName, !driver.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(BlazeTheme.primary)
                                    Text(driver)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(BlazeTheme.textSecondary)
                                }
                            }
                        }
                        
                        if let time = detailVM.vehicle.time {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                Text("Último reporte: \(time)")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(BlazeTheme.textMuted)
                        }
                    }
                    .padding(18)
                    .background(BlazeTheme.surface)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(BlazeTheme.surfaceBorder, lineWidth: 1)
                    )
                    
                    // Quick Remote Commands Action Bar
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Comandos Remotos (Inmovilizador)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(BlazeTheme.textSecondary)
                        
                        HStack(spacing: 12) {
                            // Engine Stop
                            Button {
                                detailVM.promptCommand(command: "engine_stop")
                                showCommandModal = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "power")
                                    Text("Apagar Motor")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(BlazeTheme.danger)
                                .cornerRadius(12)
                            }
                            
                            // Engine Resume
                            Button {
                                detailVM.promptCommand(command: "engine_resume")
                                showCommandModal = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "bolt.fill")
                                    Text("Habilitar")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(BlazeTheme.moving)
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Telemetry Gauges Grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Telemetría en Vivo")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(BlazeTheme.textSecondary)
                        
                        TelemetryGaugesView(vehicle: detailVM.vehicle)
                    }
                    
                    // Mini Map Position Preview
                    if let lat = detailVM.vehicle.lat, let lng = detailVM.vehicle.lng {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Ubicación Actual")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(BlazeTheme.textSecondary)
                                
                                Spacer()
                                
                                Button {
                                    UIPasteboard.general.string = "\(lat), \(lng)"
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.doc")
                                        Text(String(format: "%.4f, %.4f", lat, lng))
                                    }
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(BlazeTheme.primary)
                                }
                            }
                            
                            Map(position: .constant(.camera(MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng), distance: 1500)))) {
                                Annotation(detailVM.vehicle.plate, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)) {
                                    VehicleAnnotationView(vehicle: detailVM.vehicle, isSelected: true)
                                }
                            }
                            .frame(height: 180)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(BlazeTheme.surfaceBorder, lineWidth: 1)
                            )
                            
                            // Navigation Shortcuts
                            HStack(spacing: 10) {
                                Button {
                                    if let url = URL(string: "maps://?daddr=\(lat),\(lng)&dirflg=d"), UIApplication.shared.canOpenURL(url) {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "map.fill")
                                        Text("Apple Maps")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(BlazeTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(BlazeTheme.surface)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(BlazeTheme.surfaceBorder, lineWidth: 1)
                                    )
                                }
                                
                                Button {
                                    let googleURL = URL(string: "comgooglemaps://?daddr=\(lat),\(lng)&directionsmode=driving")
                                    let webURL = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(lat),\(lng)")!
                                    if let gUrl = googleURL, UIApplication.shared.canOpenURL(gUrl) {
                                        UIApplication.shared.open(gUrl)
                                    } else {
                                        UIApplication.shared.open(webURL)
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                        Text("Google Maps")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(BlazeTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(BlazeTheme.surface)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(BlazeTheme.surfaceBorder, lineWidth: 1)
                                    )
                                }
                                
                                Button {
                                    let wazeURL = URL(string: "waze://?ll=\(lat),\(lng)&navigate=yes")
                                    let webURL = URL(string: "https://waze.com/ul?ll=\(lat),\(lng)&navigate=yes")!
                                    if let wUrl = wazeURL, UIApplication.shared.canOpenURL(wUrl) {
                                        UIApplication.shared.open(wUrl)
                                    } else {
                                        UIApplication.shared.open(webURL)
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "car.fill")
                                        Text("Waze")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(BlazeTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(BlazeTheme.surface)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(BlazeTheme.surfaceBorder, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(detailVM.vehicle.plate)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCommandModal) {
            RemoteCommandSheet(detailVM: detailVM)
                .presentationDetents([.medium])
        }
    }
}
