//
//  ContentView.swift
//  HelloAR
//
//  Created by Aleksy Krolczyk on 03/09/2022.
//

import SwiftUI
import RealityKit
import ARKit

struct ContentView : View {
    var body: some View {
        return ARViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}



struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        ARViewController.shared.startSession()
        return ARViewController.shared.arView
        
    }
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ARViewController.shared)
    }
}
#endif
