//
//  EditRuleForm.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 02.12.2024.
//

import SwiftUI

struct EditRuleForm: View {
    @Binding var rule: Rule
    @Binding var isPresented: Bool
    
    @AppStorage("rules") private var rules: [Rule] = []
    
    var body: some View {
        RuleForm(
            rule: rule,
            onCancel: {
                isPresented.toggle()
            },
            onSave: {
                rule = $0
                isPresented.toggle()
            },
            onDelete: { rule in
                rules.removeAll {
                    $0 == rule
                }
                isPresented.toggle()
            }
        )
    }
}

struct NewRuleForm: View {
    @Binding var isPresented: Bool
    
    @AppStorage("rules") private var rules: [Rule] = []
    
    var body: some View {
        RuleForm(
            rule: nil,
            onCancel: {
                isPresented.toggle()
            },
            onSave: {
                rules.append($0)
                isPresented.toggle()
            },
            onDelete: { rule in
                rules.removeAll {
                    $0 == rule
                }
                isPresented.toggle()
            }
        )
    }
}

struct RuleForm: View {
    var rule: Rule?
    
    var onCancel: () -> Void
    var onSave: (Rule) -> Void
    var onDelete: (Rule) -> Void

    @State private var openWithPresented = false
    
    @State private var regex: String = "github.com"
    @State private var testUrls: String = "https://github.com/AlexStrNik/Browserino\nhttps://x.com/alexstrnik"
    @State private var url: URL?
    
    private var compiledRegex: Regex<AnyRegexOutput>? {
        return try? Regex(regex).ignoresCase()
    }
    
    private var attributtedText: AttributedString {
        var string = AttributedString(testUrls)
        guard let compiledRegex else {
            return string
        }
        
        for line in testUrls.split(separator: "\n") {
            if line.firstMatch(of: compiledRegex) != nil, let range = string.range(of: line) {
                string[range].foregroundColor = .red
            }
        }
        
        return string
    }
    
    var body: some View {
        let bundle = rule.map { Bundle(url: $0.app)! }

        Form {
            Section(
                header: Text("General")
                    .font(.headline)
            ) {
                TextField("Regex:", text: $regex)
                    .font(
                        .system(size: 14)
                    )
                
                LabeledContent("Test URLs:") {
                    TextEditor(text: $testUrls)
                        .font(
                            .system(size: 14)
                        )
                }
                
                Text(attributtedText)
                    .font(
                        .system(size: 14)
                    )
            }
            
            Spacer()
                .frame(height: 32)
            
            
            LabeledContent("Application:") {
                Button(action: {
                    openWithPresented.toggle()
                }) {
                    Text("Open with")
                }
                .fileImporter(
                    isPresented: $openWithPresented,
                    allowedContentTypes: [.application]
                ) {
                    if case .success(let url) = $0 {
                        self.url = url
                    }
                }
                
                if let bundle {
                    Text("\(bundle.infoDictionary!["CFBundleName"] as! String)")
                        .padding(.horizontal, 5)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
                .frame(height: 32)
            
            HStack {
                Button(role: .cancel, action: onCancel) {
                    Text("Cancel")
                }
                
                Button(role: .destructive, action: {
                    
                }) {
                    Text("Delete")
                }
                
                Spacer()
                
                Button(action: {
                    guard let url else {
                        return
                    }
                    
                    onSave(
                        Rule(
                            regex: regex,
                            app: url
                        )
                    )
                }) {
                    Text("Save")
                }
                .disabled(compiledRegex == nil || url == nil)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .frame(minWidth: 500)
        .onAppear {
            regex = rule?.regex ?? ""
            url = rule?.app
        }
    }
}
