//
//  PadView.swift
//  DrumPadTry
//
//  Created by Marvin Krüger on 18.12.25.
//

import SwiftUI

struct PadView: View {
    let config: PadConfiguration
    @ObservedObject var audioEngine: AudioEngineManager
    
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    
    private var isActive: Bool {
        audioEngine.activeToggles.contains(config.id)
    }
    
    private var isSelectedForSequencer: Bool {
        audioEngine.selectedPadForSequencer == config.id
    }
    
    private var hasPattern: Bool {
        audioEngine.hasPattern(config.id)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                // Glow
                if isPressed || isActive || isSelectedForSequencer {
                    RoundedRectangle(cornerRadius: size * 0.15)
                        .fill(config.colorTheme.glow)
                        .blur(radius: 6)
                        .scaleEffect(1.05)
                }
                
                // Main pad
                RoundedRectangle(cornerRadius: size * 0.12)
                    .fill(
                        LinearGradient(
                            colors: [
                                isPressed || isActive || isSelectedForSequencer ? config.colorTheme.primary : config.colorTheme.dim,
                                isPressed || isActive || isSelectedForSequencer ? config.colorTheme.primary.opacity(0.6) : config.colorTheme.dim.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.12)
                            .stroke(Color.white.opacity(isPressed || isActive || isSelectedForSequencer ? 0.4 : 0.1), lineWidth: 1)
                    )
                
                // Label
                VStack(spacing: 0) {
                    if config.synthType == .kick || config.synthType == .snare || config.synthType == .hihat {
                        Image(systemName: drumIcon)
                            .font(.system(size: size * 0.18, weight: .medium))
                            .foregroundColor(labelColor)
                    }
                    
                    Text(config.label)
                        .font(.system(size: size * 0.13, weight: .bold, design: .rounded))
                        .foregroundColor(labelColor)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                
                // Pattern indicator
                if hasPattern {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.white)
                                .frame(width: 5, height: 5)
                                .padding(3)
                        }
                        Spacer()
                    }
                }
            }
            .scaleEffect(scale)
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: scale)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed { handlePressStart() }
                    }
                    .onEnded { _ in handlePressEnd() }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.4)
                    .onEnded { _ in handleLongPress() }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private var drumIcon: String {
        switch config.synthType {
        case .kick: return "circle.fill"
        case .snare: return "square.fill"
        case .hihat: return "triangle.fill"
        default: return "waveform"
        }
    }
    
    private var labelColor: Color {
        (isPressed || isActive || isSelectedForSequencer) ? .white : config.colorTheme.primary.opacity(0.7)
    }
    
    private func handlePressStart() {
        isPressed = true
        scale = 0.9
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        if audioEngine.isSequencerMode && isSelectedForSequencer { return }
        
        switch config.triggerMode {
        case .oneShot, .hold, .loop:
            audioEngine.triggerPad(config.id, frequency: config.frequency)
        case .toggle:
            audioEngine.togglePad(config.id, frequency: config.frequency)
        }
    }
    
    private func handlePressEnd() {
        isPressed = false
        scale = 1.0
        if config.triggerMode == .hold {
            audioEngine.releasePad(config.id)
        }
    }
    
    private func handleLongPress() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        audioEngine.selectPadForSequencer(config.id)
    }
}

// MARK: - Sequencer View

struct SequencerView: View {
    @ObservedObject var audioEngine: AudioEngineManager
    let padConfig: PadConfiguration?
    let allPads: [PadConfiguration]
    
    var body: some View {
        VStack(spacing: 6) {
            // Header row
            HStack(spacing: 8) {
                if let config = padConfig {
                    Circle()
                        .fill(config.colorTheme.primary)
                        .frame(width: 10, height: 10)
                    
                    Text(config.label)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("PATTERN")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Random melody button (only for melodic sounds)
                if let config = padConfig, isMelodicSound(config.synthType) {
                    Button(action: generateRandomMelody) {
                        HStack(spacing: 3) {
                            Image(systemName: "dice.fill")
                                .font(.system(size: 9))
                            Text("MELODY")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().stroke(Color.yellow.opacity(0.5), lineWidth: 1))
                    }
                }
                
                // Random beat button (for drums)
                if let config = padConfig, isDrumSound(config.synthType) {
                    Button(action: generateRandomBeat) {
                        HStack(spacing: 3) {
                            Image(systemName: "dice.fill")
                                .font(.system(size: 9))
                            Text("BEAT")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().stroke(Color.orange.opacity(0.5), lineWidth: 1))
                    }
                }
                
                Button(action: clearPattern) {
                    Text("CLR")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Capsule().stroke(Color.red.opacity(0.4), lineWidth: 1))
                }
                
                Button(action: closeSequencer) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
            }
            
            // Step grid
            HStack(spacing: 2) {
                ForEach(0..<16, id: \.self) { step in
                    let isActive = audioEngine.patterns[audioEngine.selectedPadForSequencer ?? -1]?.steps[step] ?? false
                    let isCurrent = audioEngine.isPlaying && audioEngine.currentBeat == step
                    
                    Button(action: { toggleStep(step) }) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isActive ? (padConfig?.colorTheme.primary ?? .green) : Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(isCurrent ? Color.white : Color.white.opacity(step % 4 == 0 ? 0.2 : 0.1), lineWidth: isCurrent ? 2 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 36)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(padConfig?.colorTheme.primary.opacity(0.3) ?? Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func isMelodicSound(_ type: SynthType) -> Bool {
        [.bass, .lead, .pad, .pluck, .fx].contains(type)
    }
    
    private func isDrumSound(_ type: SynthType) -> Bool {
        [.kick, .snare, .hihat].contains(type)
    }
    
    private func toggleStep(_ step: Int) {
        if let padId = audioEngine.selectedPadForSequencer {
            audioEngine.toggleStep(step, forPad: padId)
            if let config = padConfig {
                audioEngine.triggerPad(padId, frequency: config.frequency)
            }
        }
    }
    
    private func clearPattern() {
        if let id = audioEngine.selectedPadForSequencer {
            audioEngine.clearPattern(id)
        }
    }
    
    private func closeSequencer() {
        audioEngine.selectedPadForSequencer = nil
        audioEngine.isSequencerMode = false
    }
    
    private func generateRandomMelody() {
        guard let padId = audioEngine.selectedPadForSequencer,
              let config = padConfig else { return }
        
        // Find all pads of the same type in the same row
        let rowStart = (padId / 8) * 8
        let rowPads = allPads.filter { $0.id >= rowStart && $0.id < rowStart + 8 }
        
        // Clear all patterns in this row first
        for pad in rowPads {
            audioEngine.clearPattern(pad.id)
        }
        
        // Generate a musical pattern using pentatonic-like selection
        // Use steps that create a nice rhythmic feel
        let rhythmPatterns: [[Int]] = [
            [0, 4, 8, 12],           // Quarter notes
            [0, 3, 6, 10, 14],       // Syncopated
            [0, 2, 4, 7, 10, 12],    // Busy
            [0, 4, 6, 8, 12, 14],    // Groovy
            [0, 3, 8, 11],           // Sparse syncopated
            [0, 2, 6, 8, 10, 14],    // Funky
        ]
        
        let selectedRhythm = rhythmPatterns.randomElement() ?? rhythmPatterns[0]
        
        // Assign notes from the row to create a melody
        // Prefer root notes, fifths, and thirds for a pleasing sound
        let notePreferences = [0, 4, 2, 5, 7, 3, 6, 1] // Index preferences for scale degrees
        
        for step in selectedRhythm {
            // Pick a note with weighted randomness favoring consonant intervals
            let noteIndex: Int
            if Bool.random() && Bool.random() { // 25% chance for less common notes
                noteIndex = notePreferences[Int.random(in: 3..<8)]
            } else { // 75% chance for root, third, or fifth
                noteIndex = notePreferences[Int.random(in: 0..<3)]
            }
            
            let padIndex = rowStart + min(noteIndex, rowPads.count - 1)
            audioEngine.patterns[padIndex]?.steps[step] = true
        }
        
        // Add occasional passing tones
        if Bool.random() {
            let passingStep = Int.random(in: 0..<16)
            let passingNote = rowStart + Int.random(in: 0..<8)
            audioEngine.patterns[passingNote]?.steps[passingStep] = true
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func generateRandomBeat() {
        guard let padId = audioEngine.selectedPadForSequencer,
              let config = padConfig else { return }
        
        audioEngine.clearPattern(padId)
        
        var pattern: [Bool] = Array(repeating: false, count: 16)
        
        switch config.synthType {
        case .kick:
            // Classic kick patterns
            let kickPatterns: [[Int]] = [
                [0, 8],                 // Simple
                [0, 4, 8, 12],          // Four on the floor
                [0, 6, 8, 14],          // Syncopated
                [0, 3, 8, 11],          // Off-beat
                [0, 4, 10, 12],         // House variation
            ]
            let selected = kickPatterns.randomElement() ?? [0, 8]
            for step in selected { pattern[step] = true }
            
        case .snare:
            // Snare on 2 and 4 (steps 4 and 12 in 16th notes)
            let snarePatterns: [[Int]] = [
                [4, 12],                // Classic backbeat
                [4, 10, 12],            // With ghost note
                [4, 7, 12, 15],         // Busy
                [4, 12, 14],            // Funk
            ]
            let selected = snarePatterns.randomElement() ?? [4, 12]
            for step in selected { pattern[step] = true }
            
        case .hihat:
            // Various hihat patterns
            let hihatPatterns: [[Int]] = [
                [0, 2, 4, 6, 8, 10, 12, 14],     // 8th notes
                [0, 4, 8, 12],                   // Quarter notes
                [0, 2, 4, 6, 8, 10, 12, 14].filter { _ in Bool.random() }, // Random 8ths
                Array(0..<16),                   // 16th notes
                [2, 6, 10, 14],                  // Off-beat
            ]
            let selected = hihatPatterns.randomElement() ?? [0, 4, 8, 12]
            for step in selected { pattern[step] = true }
            
        default:
            // Random pattern for other sounds
            for i in 0..<16 where Bool.random() && Bool.random() {
                pattern[i] = true
            }
        }
        
        audioEngine.patterns[padId]?.steps = pattern
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Transport Controls

struct TransportControlsView: View {
    @ObservedObject var audioEngine: AudioEngineManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Play/Stop
            Button(action: togglePlayback) {
                Image(systemName: audioEngine.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(audioEngine.isPlaying ? .red : .green)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .overlay(Circle().stroke(audioEngine.isPlaying ? Color.red.opacity(0.5) : Color.green.opacity(0.5), lineWidth: 2))
                    )
            }
            
            // BPM
            HStack(spacing: 4) {
                Button(action: { audioEngine.setBPM(audioEngine.bpm - 5) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                VStack(spacing: -2) {
                    Text("\(Int(audioEngine.bpm))")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                    Text("BPM")
                        .font(.system(size: 7, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                }
                .frame(width: 44)
                
                Button(action: { audioEngine.setBPM(audioEngine.bpm + 5) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            Spacer()
            
            // Beat indicators - compact
            HStack(spacing: 2) {
                ForEach(0..<16, id: \.self) { beat in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(beatColor(for: beat))
                        .frame(width: 10, height: beat % 4 == 0 ? 14 : 10)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.3))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
        )
    }
    
    private func togglePlayback() {
        if audioEngine.isPlaying {
            audioEngine.stopBeat()
        } else {
            audioEngine.startBeat()
        }
    }
    
    private func beatColor(for beat: Int) -> Color {
        if audioEngine.isPlaying && audioEngine.currentBeat == beat {
            return .green
        } else if beat % 4 == 0 {
            return Color.white.opacity(0.25)
        }
        return Color.white.opacity(0.12)
    }
}

// MARK: - Beat Indicator (for reference)

struct BeatIndicatorView: View {
    let beatIndex: Int
    let currentBeat: Int
    let isPlaying: Bool
    
    var body: some View {
        Circle()
            .fill(isPlaying && beatIndex == currentBeat ? Color.green : Color.gray.opacity(0.3))
            .frame(width: 8, height: 8)
    }
}

#Preview {
    ContentView()
}
