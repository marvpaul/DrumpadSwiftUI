//
//  ContentView.swift
//  DrumPadTry
//
//  Created by Marvin Krüger on 18.12.25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioEngine = AudioEngineManager.shared
    @State private var isInitialized = false
    
    private let gridSize = 8
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(red: 0.03, green: 0.03, blue: 0.05)
                    .ignoresSafeArea()
                
                VStack(spacing: 4) {
                    // Header
                    headerView
                        .padding(.horizontal, 8)
                    
                    // 8x8 Instrument Grid
                    instrumentGrid(geometry: geometry)
                        .padding(.horizontal, 4)
                    
                    // Transport bar
                    TransportBar(audioEngine: audioEngine)
                        .padding(.horizontal, 6)
                        .padding(.bottom, 4)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            initializeAudio()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 24, height: 24)
                    
                    Grid(horizontalSpacing: 1.5, verticalSpacing: 1.5) {
                        GridRow {
                            Circle().fill(Color.white.opacity(0.9)).frame(width: 3, height: 3)
                            Circle().fill(Color.white.opacity(0.9)).frame(width: 3, height: 3)
                        }
                        GridRow {
                            Circle().fill(Color.white.opacity(0.6)).frame(width: 3, height: 3)
                            Circle().fill(Color.white.opacity(0.6)).frame(width: 3, height: 3)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: -2) {
                    Text("BEAT")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("MAKER")
                        .font(.system(size: 7, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            // Status
            HStack(spacing: 5) {
                let activeCount = audioEngine.instruments.filter { $0.hasActiveSteps }.count
                if activeCount > 0 {
                    HStack(spacing: 2) {
                        Circle().fill(Color.green).frame(width: 4, height: 4)
                        Text("\(activeCount)")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.white.opacity(0.1)))
                }
                
                if audioEngine.isPlaying {
                    HStack(spacing: 2) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 4, height: 4)
                            .opacity(audioEngine.currentStep % 2 == 0 ? 1 : 0.4)
                        Text("LIVE")
                            .font(.system(size: 6, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.red.opacity(0.2)))
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Instrument Grid
    
    private func instrumentGrid(geometry: GeometryProxy) -> some View {
        let spacing: CGFloat = 3
        let horizontalPadding: CGFloat = 8
        let headerHeight: CGFloat = 32
        let transportHeight: CGFloat = 50
        let verticalSpacing: CGFloat = 12
        
        let availableWidth = geometry.size.width - horizontalPadding
        let availableHeight = geometry.size.height - headerHeight - transportHeight - verticalSpacing
        
        let totalHSpacing = spacing * CGFloat(gridSize - 1)
        let totalVSpacing = spacing * CGFloat(gridSize - 1)
        
        let padWidth = (availableWidth - totalHSpacing) / CGFloat(gridSize)
        let padHeight = (availableHeight - totalVSpacing) / CGFloat(gridSize)
        let padSize = min(padWidth, padHeight)
        
        return VStack(spacing: spacing) {
            ForEach(0..<gridSize, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<gridSize, id: \.self) { col in
                        let index = row * gridSize + col
                        if index < audioEngine.instruments.count {
                            InstrumentPadView(
                                instrument: audioEngine.instruments[index],
                                audioEngine: audioEngine,
                                isCompact: true
                            )
                            .frame(width: padSize, height: padSize)
                        }
                    }
                }
            }
        }
    }
    
    private func initializeAudio() {
        guard !isInitialized else { return }
        isInitialized = true
        audioEngine.initializeInstruments()
    }
}

#Preview {
    ContentView()
}
