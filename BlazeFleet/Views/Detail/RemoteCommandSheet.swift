import SwiftUI

public struct RemoteCommandSheet: View {
    @ObservedObject var detailVM: VehicleDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    public init(detailVM: VehicleDetailViewModel) {
        self.detailVM = detailVM
    }
    
    var commandTitle: String {
        switch detailVM.pendingCommand {
        case "engine_stop": return "Apagar Motor Remotamente"
        case "engine_resume": return "Habilitar Encendido de Motor"
        case "locate": return "Solicitar Posición Instantánea"
        case "arm": return "Activar Alarma / Inmovilizador"
        case "disarm": return "Desactivar Alarma / Inmovilizador"
        default: return "Comando Remoto"
        }
    }
    
    var commandDescription: String {
        switch detailVM.pendingCommand {
        case "engine_stop":
            return "Esta acción enviará un pulso de corte de ignición al rastreador GPS de la unidad \(detailVM.vehicle.plate). El vehículo no podrá encender hasta que se envíe el comando de reanudación."
        case "engine_resume":
            return "Esta acción restablecerá el relevador de corte de la unidad \(detailVM.vehicle.plate), permitiendo el arranque normal del vehículo."
        default:
            return "Se enviará el comando satelital a la unidad \(detailVM.vehicle.plate)."
        }
    }
    
    public var body: some View {
        ZStack {
            BlazeTheme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header Icon
                ZStack {
                    Circle()
                        .fill(detailVM.pendingCommand == "engine_stop" ? BlazeTheme.danger.opacity(0.15) : BlazeTheme.primaryGlow)
                        .frame(width: 72, height: 72)
                    Image(systemName: detailVM.pendingCommand == "engine_stop" ? "exclamationmark.shield.fill" : "bolt.shield.fill")
                        .font(.system(size: 36))
                        .foregroundColor(detailVM.pendingCommand == "engine_stop" ? BlazeTheme.danger : BlazeTheme.primary)
                }
                .padding(.top, 16)
                
                VStack(spacing: 8) {
                    Text(commandTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(BlazeTheme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(commandDescription)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(BlazeTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 16)
                }
                
                if detailVM.pendingCommand == "engine_stop" {
                    HStack(spacing: 8) {
                        Image(systemName: "faceid")
                            .foregroundColor(BlazeTheme.primary)
                        Text("Requiere autenticación biométrica Face ID / Touch ID")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(BlazeTheme.textSecondary)
                    }
                    .padding(10)
                    .background(BlazeTheme.surface)
                    .cornerRadius(8)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button {
                        Task {
                            await detailVM.confirmAndExecuteCommand()
                            dismiss()
                        }
                    } label: {
                        HStack {
                            if detailVM.isExecutingCommand {
                                ProgressView().tint(.white)
                            } else {
                                Text("Confirmar y Enviar Comando")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(detailVM.pendingCommand == "engine_stop" ? BlazeTheme.danger : BlazeTheme.primary)
                        .cornerRadius(14)
                    }
                    .disabled(detailVM.isExecutingCommand)
                    
                    Button {
                        detailVM.pendingCommand = nil
                        dismiss()
                    } label: {
                        Text("Cancelar")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(BlazeTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                }
            }
            .padding(20)
        }
    }
}
