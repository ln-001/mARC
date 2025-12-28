//
//  ConnectionBarView.swift
//  mARC
//
//  Created by LN on 27/12/2025.
//

import SwiftUI

struct ConnectionBar: View {
    @ObservedObject var irc: IRCClient
    @Binding var host: String
    @Binding var port: String
    @Binding var useSSL: Bool
    @Binding var nickname: String
    @Binding var saslUsername: String
    @Binding var saslPassword: String
    var onConnect: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            
            TextField("Host", text: $host)
                .textFieldStyle(.roundedBorder)
                .frame(width: 150)
            
            TextField("Port", text: $port)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
            
            Toggle("SSL", isOn: $useSSL)
            
            TextField("Nickname", text: $nickname)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
            
            TextField("SASL User", text: $saslUsername)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
            
            SecureField("Password", text: $saslPassword)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
            
            Spacer()
            
            connectionButton
        }
        .padding(8)
    }
    
    @ViewBuilder
    var connectionButton: some View {
        if irc.isConnected {
            Button("Disconnect") {
                irc.disconnect()
            }
        } else if irc.isConnecting {
            Button("Cancel") {
                irc.disconnect()
            }
        } else {
            Button("Connect") {
                onConnect()
            }
        }
    }
    
    var statusColor: Color {
        if irc.isConnected { return .green }
        if irc.isConnecting { return .yellow }
        return .red
    }
}
