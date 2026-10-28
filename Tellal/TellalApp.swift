//
//  TellalApp.swift
//  Tellal
//
//  Created by Ufuk Celen on 28.10.2026.
//

import SwiftUI

@main
struct TellalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 1040, height: 720)
    }
}
