import SwiftUI

public struct LoginView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var showSettings = false
    @State private var customServerURL = APIClient.shared.baseURL
    @State private var showPassword = false
    
    public init(authVM: AuthViewModel) {
        self.authVM = authVM
    }
    
    public var body: some View {
        ZStack {
            BlazeTheme.background.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Brand Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(BlazeTheme.primaryGlow)
                            .frame(width: 80, height: 80)
                        Image(systemName: "location.north.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 52, height: 52)
                            .foregroundColor(BlazeTheme.primary)
                    }
                    
                    Text("BLAZEFLEET")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(BlazeTheme.textPrimary)
                        .tracking(2)
                    
                    Text("Plataforma GPS & Telemetría Satelital")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(BlazeTheme.textSecondary)
                }
                
                // Credentials Box
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Correo corporativo")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(BlazeTheme.textSecondary)
                        
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(BlazeTheme.textMuted)
                            TextField("usuario@empresa.com", text: $authVM.email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .foregroundColor(BlazeTheme.textPrimary)
                        }
                        .padding()
                        .background(BlazeTheme.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(BlazeTheme.surfaceBorder, lineWidth: 1)
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Contraseña")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(BlazeTheme.textSecondary)
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(BlazeTheme.textMuted)
                            if showPassword {
                                TextField("Contraseña", text: $authVM.password)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .foregroundColor(BlazeTheme.textPrimary)
                            } else {
                                SecureField("••••••••", text: $authVM.password)
                                    .foregroundColor(BlazeTheme.textPrimary)
                            }
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(BlazeTheme.textMuted)
                                    .font(.system(size: 14))
                            }
                        }
                        .padding()
                        .background(BlazeTheme.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(BlazeTheme.surfaceBorder, lineWidth: 1)
                        )
                    }
                    
                    // Quick Accounts Selector
                    HStack(spacing: 8) {
                        Button {
                            authVM.fillAccount(email: "flotillas@telemarch.com.do", pass: "IU1IAy6bgFAuMNjq")
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 11))
                                Text("Telemarch")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(authVM.email.contains("telemarch") ? BlazeTheme.primary.opacity(0.18) : BlazeTheme.surface)
                            .foregroundColor(authVM.email.contains("telemarch") ? BlazeTheme.primary : BlazeTheme.textSecondary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(authVM.email.contains("telemarch") ? BlazeTheme.primary : BlazeTheme.surfaceBorder, lineWidth: 1)
                            )
                        }
                        
                        Button {
                            authVM.fillAccount(email: "owner@demo.do", pass: "Demo1234!")
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "car.2.fill")
                                    .font(.system(size: 11))
                                Text("Demo")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(authVM.email.contains("demo") ? BlazeTheme.primary.opacity(0.18) : BlazeTheme.surface)
                            .foregroundColor(authVM.email.contains("demo") ? BlazeTheme.primary : BlazeTheme.textSecondary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(authVM.email.contains("demo") ? BlazeTheme.primary : BlazeTheme.surfaceBorder, lineWidth: 1)
                            )
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 2)
                    
                    if let err = authVM.errorMessage {
                        Text(err)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(BlazeTheme.danger)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    
                    Button {
                        Task { await authVM.login() }
                    } label: {
                        HStack {
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Iniciar Sesión")
                                    .font(.system(size: 16, weight: .bold))
                                Image(systemName: "arrow.right")
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(BlazeTheme.primary)
                        .cornerRadius(14)
                        .shadow(color: BlazeTheme.primaryGlow, radius: 10, y: 4)
                    }
                    .disabled(authVM.isLoading)
                    .padding(.top, 10)
                }
                .padding(.horizontal, 28)
                
                Spacer()
                
                // Server Config Link
                Button {
                    showSettings = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "network")
                        Text("Servidor: \(URL(string: APIClient.shared.baseURL)?.host ?? "fleet.blaze.do")")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BlazeTheme.textMuted)
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showSettings) {
            ServerConfigSheet(serverURL: $customServerURL)
        }
    }
}

struct ServerConfigSheet: View {
    @Binding var serverURL: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                BlazeTheme.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 18) {
                    Text("Dirección del API Backend")
                        .font(.headline)
                        .foregroundColor(BlazeTheme.textPrimary)
                    
                    TextField("https://fleet.blaze.do", text: $serverURL)
                        .padding()
                        .background(BlazeTheme.surface)
                        .cornerRadius(10)
                        .foregroundColor(BlazeTheme.textPrimary)
                    
                    Button("Guardar") {
                        APIClient.shared.baseURL = serverURL
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(BlazeTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}
