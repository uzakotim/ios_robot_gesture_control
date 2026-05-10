import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var commandManager: CommandManager
    
    @State private var robotIP: String = ""
    @State private var robotPort: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(gradient: Gradient(colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Robot Settings")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        
                        // Connection Section
                        SettingsSection(title: "Connection") {
                            VStack(spacing: 15) {
                                CustomTextField(label: "Robot IP", text: $robotIP, placeholder: "192.168.1.100")
                                CustomTextField(label: "Port", text: $robotPort, placeholder: "8080")
                                    .keyboardType(.numberPad)
                            }
                        }
                        
                        // Preferences Section
                        SettingsSection(title: "Preferences") {
                            Toggle(isOn: $commandManager.isAudioFeedbackEnabled) {
                                Label("Audio Feedback", systemImage: "speaker.wave.2.fill")
                                    .foregroundColor(.white)
                            }
                            .tint(.blue)
                        }
                        
                        // Save Button
                        Button(action: saveSettings) {
                            Text("Save Changes")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue)
                                .cornerRadius(15)
                                .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 5)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        robotIP = UserDefaults.standard.string(forKey: "robot_ip") ?? "192.168.1.100"
        robotPort = UserDefaults.standard.string(forKey: "robot_port") ?? "8080"
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(robotIP, forKey: "robot_ip")
        UserDefaults.standard.set(robotPort, forKey: "robot_port")
        
        if let port = UInt16(robotPort) {
            commandManager.setupUDP(host: robotIP, port: port)
        }
        
        dismiss()
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.gray)
                .padding(.leading, 5)
            
            VStack {
                content
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

struct CustomTextField: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.footnote)
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
                .foregroundColor(.white)
                .accentColor(.blue)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
