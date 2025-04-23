//
//  ContentView.swift
//  C1 Assist
//
//  Created by Koray Birand on 23/04/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var projectName: String = ""
    @State private var folderCount: String = ""
    @State private var projectLocation: URL?
    @State private var isShowingFilePicker = false
    @State private var isGenerating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Text("C1 Project Generator")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Koray Birand Studio")
                .font(.system(size: 18))
                .fontWeight(.light)
                .padding(.top, -24)
            
            // Project Name Input
            VStack(alignment: .leading) {
                Text("Project Name:")
                    .fontWeight(.medium)
                TextField("Enter project name", text: $projectName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.bottom, 5)
            }
            
            // Folder Count Input
            VStack(alignment: .leading) {
                Text("Folder Count:")
                    .fontWeight(.medium)
                TextField("Enter number of folders", text: Binding(
                    get: { folderCount },
                    set: { newValue in
                        // Only allow numeric characters
                        folderCount = newValue.filter { "0123456789".contains($0) }
                    }
                ))
                .textFieldStyle(.roundedBorder)
                .padding(.bottom, 5)
            }
            
            // Project Location Selection
            VStack(alignment: .leading) {
                Text("Project Location:")
                    .fontWeight(.medium)
                HStack {
                    Text(projectLocation?.path ?? "No location selected")
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(5)
                    
                    Button("Browse") {
                        isShowingFilePicker = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Spacer()
            
            // Generate Button
            Button(action: {
                generateProject()
            }) {
                Text("Generate")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(projectName.isEmpty || folderCount.isEmpty || projectLocation == nil || isGenerating)
            .opacity((projectName.isEmpty || folderCount.isEmpty || projectLocation == nil || isGenerating) ? 0.6 : 1)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .persistWindowState()
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedURL = try result.get().first else { return }
                // Ensure we have access to this URL
                if selectedURL.startAccessingSecurityScopedResource() {
                    projectLocation = selectedURL
                    // Release the security-scoped resource when done
                    selectedURL.stopAccessingSecurityScopedResource()
                }
            } catch {
                print("Error selecting directory: \(error.localizedDescription)")
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func generateProject() {
        guard let count = Int(folderCount), count > 0 else {
            alertTitle = "Invalid Input"
            alertMessage = "Please enter a valid number for folder count."
            showAlert = true
            return
        }
        
        guard let location = projectLocation else {
            alertTitle = "Missing Location"
            alertMessage = "Please select a project location."
            showAlert = true
            return
        }
        
        isGenerating = true
        
        // Start accessing the security-scoped resource
        let securityScopedAccess = location.startAccessingSecurityScopedResource()
        
        // Create project structure
        let projectManager = ProjectManager()
        do {
            try projectManager.createProject(
                name: projectName,
                folderCount: count,
                location: location
            )
            
            alertTitle = "Success"
            alertMessage = "Project '\(projectName)' has been generated successfully."
        } catch {
            print("Project generation error: \(error)")
            alertTitle = "Error"
            alertMessage = "Failed to generate project: \(error.localizedDescription)"
        }
        
        // Stop accessing the security-scoped resource
        if securityScopedAccess {
            location.stopAccessingSecurityScopedResource()
        }
        
        showAlert = true
        isGenerating = false
    }
}

#Preview {
    ContentView()
}
