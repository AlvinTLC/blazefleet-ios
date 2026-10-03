import SwiftUI

public struct FleetListView: View {
    @ObservedObject var fleetVM: FleetViewModel
    @ObservedObject var wsService = WebSocketService.shared
    
    public init(fleetVM: FleetViewModel) {
        self.fleetVM = fleetVM
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                BlazeTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(BlazeTheme.textMuted)
                        TextField("Buscar placa, modelo, chofer...", text: $fleetVM.searchQuery)
                            .foregroundColor(BlazeTheme.textPrimary)
                        if !fleetVM.searchQuery.isEmpty {
                            Button {
                                fleetVM.searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(BlazeTheme.textMuted)
                            }
                        }
                    }
                    .padding(12)
                    .background(BlazeTheme.surface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BlazeTheme.surfaceBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    
                    // Filter bar
                    StatusFilterBar(selected: $fleetVM.selectedFilter, counts: fleetVM.counts)
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                    
                    // Vehicle List
                    if fleetVM.isLoading && fleetVM.vehicles.isEmpty {
                        Spacer()
                        ProgressView()
                            .tint(BlazeTheme.primary)
                        Spacer()
                    } else if fleetVM.filteredVehicles.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "car.side.fill")
                                .font(.system(size: 44))
                                .foregroundColor(BlazeTheme.textMuted)
                            Text("No hay unidades para este filtro")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(BlazeTheme.textSecondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(fleetVM.filteredVehicles) { vehicle in
                                    NavigationLink {
                                        VehicleDetailView(vehicle: vehicle)
                                    } label: {
                                        VehicleCardView(vehicle: vehicle)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                        }
                        .refreshable {
                            await fleetVM.fetchSummary()
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Flota")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(BlazeTheme.textPrimary)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(wsService.isConnected ? BlazeTheme.moving : BlazeTheme.idle)
                                .frame(width: 6, height: 6)
                            Text(wsService.isConnected ? "En vivo" : "Reconectando...")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(BlazeTheme.textSecondary)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await fleetVM.fetchSummary() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(BlazeTheme.primary)
                    }
                }
            }
        }
        .task {
            if fleetVM.vehicles.isEmpty {
                await fleetVM.fetchSummary()
            }
        }
    }
}
