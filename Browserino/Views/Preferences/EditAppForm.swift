//
//  EditAppForm.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 10.06.2024.
//

import SwiftUI

struct EditAppForm: View {
    @Binding var app: App
    @Binding var isPresented: Bool
    
    @AppStorage("apps") private var apps: [App] = []
    
    private var hostValid: Bool {
        let url = if app.host.starts(with: /https?:\/\//) {
            app.host
        } else {
            "http://" + app.host
        }
        
        return !app.host.isEmpty && URL(string: url)?.host() != nil
    }
    
    var body: some View {
        Form {
            Section(
                header: Text("General")
                    .font(.headline)
            ) {
                TextField("Host:", text: $app.host)
                    .font(
                        .system(size: 14)
                    )
                
                LabeledContent("Open in:") {
                    BrowserTargetPicker(
                        app: Binding(
                            get: { app.app },
                            set: { if let selected = $0 { app.app = selected } }
                        ),
                        profile: $app.profile
                    )
                }
            }
            
            Spacer()
                .frame(height: 32)
            
            Section(
                header: Text("Advanced")
                    .font(.headline)
            ) {
                TextField("Replace scheme:", text: $app.schemeOverride)
                    .font(
                        .system(size: 14)
                    )
            }
            
            Spacer()
                .frame(height: 32)
            
            HStack {
                Button(role: .cancel, action: {
                    isPresented.toggle()
                }) {
                    Text("Cancel")
                }
                
                Button(role: .destructive, action: {
                    apps.removeAll {
                        $0 == app
                    }
                    isPresented.toggle()
                }) {
                    Text("Delete")
                }
                
                Spacer()
                
                Button(action: {
                    let hostUrl = if app.host.starts(with: /https?:\/\//) {
                        app.host
                    } else {
                        "http://" + app.host
                    }
                    app.host = URL(string: hostUrl)!.host()!
                    
                    isPresented.toggle()
                }) {
                    Text("Save")
                }
                .disabled(!hostValid)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .frame(minWidth: 500)
    }
}

#Preview {
    EditAppForm(
        app: .constant(
            App(
                host: "mm.2gis.one",
                schemeOverride: "",
                app: URL(string: "file:///Applications/Mattermost.app")!
            )
        ),
        isPresented: .constant(true)
    )
}
