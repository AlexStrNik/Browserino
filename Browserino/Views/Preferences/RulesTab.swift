//
//  RulesTab.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 02.12.2024.
//

import SwiftUI

struct AddRule: View {
    @State private var addPresented = false
    
    var body: some View {
        HStack {
            Image(systemName: "plus")
                .font(
                    .system(size: 14)
                )
                .opacity(0)
            
            Text("Add a new rule by typing regex and selecting an app.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
                .frame(width: 16)
            
            Button(action: {
                addPresented.toggle()
            }) {
                Text("Add new rule")
            }
            .sheet(isPresented: $addPresented) {
                NewRuleForm(
                    isPresented: $addPresented
                )
            }
        }
    }
}

struct RuleItem: View {
    @Binding var rule: Rule
    @State private var editPresented = false
    
    var body: some View {
        let bundle = Bundle(url: rule.app)!

        HStack {
            Button(action: {
                editPresented.toggle()
            }) {
                Label(rule.regex, systemImage: "pencil")
                    .font(
                        .system(size: 14)
                    )
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            
            Text(bundle.infoDictionary!["CFBundleName"] as! String)
                .font(
                    .system(size: 14)
                )
            
            
            Spacer()
                .frame(width: 8)
            
            Image(nsImage: NSWorkspace.shared.icon(forFile: bundle.bundlePath))
                .resizable()
                .frame(width: 32, height: 32)
        }
        .padding(10)
        .sheet(isPresented: $editPresented) {
            EditRuleForm(
                rule: $rule,
                isPresented: $editPresented
            )
        }
    }
}

struct RulesTab: View {
    @AppStorage("rules") private var rules: [Rule] = []
    
    var body: some View {
        VStack (alignment: .leading) {
            List {
                AddRule()

                ForEach(Array($rules.enumerated()), id: \.offset) { offset, rule in
                    RuleItem(
                        rule: rule
                    )
                }
            }
            
            Text("Type regex and choose app in which links will be opened without prompt")
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.5))
                .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 20)
    }
}

#Preview {
    RulesTab()
}
