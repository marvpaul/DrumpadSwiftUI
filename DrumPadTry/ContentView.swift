//
//  ContentView.swift
//  DrumPadTry
//
//  Created by Marvin Krüger on 18.12.25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioEngine = AudioEngineManager.shared
    @State private var pads: [PadConfiguration] = []
    @State private var isInitialized = false
    
    private let columns = 8
    private let rows = 8
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(red: 0.04, green: 0.04, blue: 0.06)
                    .ignoresSafeArea()
                
                VStack(spacing: 4) {
                    // Header
                    headerView
                        .padding(.horizontal, 8)
                    
                    // Sequencer view (if active)
                    if audioEngine.isSequencerMode, let selectedId = audioEngine.selectedPadForSequencer {
                        SequencerView(
                            audioEngine: audioEngine,
                            padConfig: pads.first(where: { $0.id == selectedId }),
                            allPads: pads
                        )
                        .padding(.horizontal, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Main pad grid - takes remaining space
                    padGrid(in: geometry)
                        .padding(.horizontal, 4)
                    
                    // Transport controls
                    TransportControlsView(audioEngine: audioEngine)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 4)
                }
            }
            .animation(.spring(response: 0.3), value: audioEngine.isSequencerMode)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            initializeAudio()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            // Logo
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 24, height: 24)
                    
                    Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                        ForEach(0..<3, id: \.self) { _ in
                            GridRow {
                                ForEach(0..<3, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 0.5)
                                        .fill(Color.white.opacity(0.9))
                                        .frame(width: 5, height: 5)
                                }
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: -2) {
                    Text("DRUM")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("SYNTH")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            // Mode indicators
            HStack(spacing: 6) {
                MiniPill(label: "LIVE", color: .green, isActive: !audioEngine.isSequencerMode)
                MiniPill(label: "SEQ", color: .cyan, isActive: audioEngine.isSequencerMode)
            }
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Pad Grid
    
    private func padGrid(in geometry: GeometryProxy) -> some View {
        let labelWidth: CGFloat = 12
        let horizontalPadding: CGFloat = 8 + labelWidth
        let spacing: CGFloat = 3
        
        // Calculate available space
        let sequencerHeight: CGFloat = audioEngine.isSequencerMode ? 100 : 0
        let headerHeight: CGFloat = 32
        let transportHeight: CGFloat = 60
        let verticalPadding: CGFloat = 20
        
        let availableWidth = geometry.size.width - horizontalPadding
        let availableHeight = geometry.size.height - headerHeight - transportHeight - sequencerHeight - verticalPadding
        
        // Calculate pad size to fit all 8 columns and 8 rows
        let totalHSpacing = spacing * CGFloat(columns - 1)
        let totalVSpacing = spacing * CGFloat(rows)
        
        let maxPadWidth = (availableWidth - totalHSpacing) / CGFloat(columns)
        let maxPadHeight = (availableHeight - totalVSpacing) / CGFloat(rows)
        let padSize = max(min(maxPadWidth, maxPadHeight), 30) // Minimum 30pt
        
        return VStack(spacing: spacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    // Row label
                    Text(["A","B","C","D","E","F","G","H"][row])
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.4))
                        .frame(width: labelWidth)
                    
                    ForEach(0..<columns, id: \.self) { col in
                        let index = row * columns + col
                        if index < pads.count {
                            PadView(config: pads[index], audioEngine: audioEngine)
                                .frame(width: padSize, height: padSize)
                        }
                    }
                }
            }
            
            // Column labels
            HStack(spacing: spacing) {
                Color.clear.frame(width: labelWidth)
                ForEach(1...columns, id: \.self) { col in
                    Text("\(col)")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.4))
                        .frame(width: padSize)
                }
            }
        }
    }
    
    // MARK: - Initialization
    
    private func initializeAudio() {
        guard !isInitialized else { return }
        isInitialized = true
        
        pads = PadConfiguration.defaultGrid()
        
        for pad in pads {
            audioEngine.createVoice(for: pad.id, type: pad.synthType, frequency: pad.frequency)
        }
    }
}

// MARK: - Mini Pill

struct MiniPill: View {
    let label: String
    let color: Color
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(isActive ? color : color.opacity(0.3))
                .frame(width: 5, height: 5)
            
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(isActive ? .white : .gray)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
                .overlay(Capsule().stroke(color.opacity(isActive ? 0.4 : 0.15), lineWidth: 1))
        )
    }
}

#Preview {
    ContentView()
}
