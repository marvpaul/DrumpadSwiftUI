//
//  PadView.swift
//  DrumPadTry
//
//  Created by Marvin Krüger on 18.12.25.
//

import SwiftUI

// MARK: - Instrument Pad View

struct InstrumentPadView: View {
    let instrument: InstrumentPad
    @ObservedObject var audioEngine: AudioEngineManager
    var isCompact: Bool = false
    
    @State private var isPressed = false
    @State private var showSequencer = false
    
    private var isCurrentlyPlaying: Bool {
        audioEngine.isPlaying && instrument.steps[audioEngine.currentStep].isActive && !instrument.isMuted
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                // Glow when playing
                if isCurrentlyPlaying {
                    RoundedRectangle(cornerRadius: size * 0.18)
                        .fill(instrument.theme.glow)
                        .blur(radius: isCompact ? 8 : 20)
                        .scaleEffect(1.1)
                }
                
                // Main pad background
                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: 0.14),
                                Color(white: 0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Top highlight
                RoundedRectangle(cornerRadius: size * 0.18)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.12), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
                
                // Border
                RoundedRectangle(cornerRadius: size * 0.18)
                    .stroke(
                        instrument.isMuted ? Color.gray.opacity(0.15) : instrument.theme.primary.opacity(isCurrentlyPlaying ? 0.95 : 0.4),
                        lineWidth: isCurrentlyPlaying ? 2 : 0.5
                    )
                
                // Content
                if isCompact {
                    compactContent(size: size)
                } else {
                    fullContent(size: size)
                }
                
                // Muted overlay
                if instrument.isMuted {
                    RoundedRectangle(cornerRadius: size * 0.18)
                        .fill(Color.black.opacity(0.7))
                    
                    Image(systemName: "speaker.slash.fill")
                        .font(.system(size: size * 0.25))
                        .foregroundColor(.gray.opacity(0.4))
                }
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.7), value: isPressed)
            .contentShape(RoundedRectangle(cornerRadius: size * 0.18))
            .onTapGesture {
                audioEngine.triggerInstrument(instrument.id)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                
                withAnimation(.easeOut(duration: 0.06)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    withAnimation {
                        isPressed = false
                    }
                }
            }
            .onLongPressGesture(minimumDuration: 0.35) {
                showSequencer = true
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        }
        .sheet(isPresented: $showSequencer) {
            SequencerSheet(instrument: instrument, audioEngine: audioEngine)
        }
    }
    
    // MARK: - Compact Content (for 8x8 grid)
    
    private func compactContent(size: CGFloat) -> some View {
        ZStack {
            // Mini circular sequencer
            MiniCircularSequencer(
                instrument: instrument,
                currentStep: audioEngine.currentStep,
                isPlaying: audioEngine.isPlaying,
                size: size * 0.75
            )
            
            // Center icon
            VStack(spacing: 1) {
                Image(systemName: instrument.instrument.icon)
                    .font(.system(size: size * 0.22, weight: .semibold))
                    .foregroundColor(instrument.isMuted ? .gray.opacity(0.3) : instrument.theme.primary)
                
                if instrument.hasActiveSteps && !instrument.isMuted {
                    Circle()
                        .fill(instrument.theme.primary)
                        .frame(width: 3, height: 3)
                }
            }
        }
    }
    
    // MARK: - Full Content
    
    private func fullContent(size: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: instrument.instrument.icon)
                    .font(.system(size: size * 0.08, weight: .semibold))
                    .foregroundColor(instrument.isMuted ? .gray.opacity(0.4) : instrument.theme.primary)
                
                Text(instrument.instrument.rawValue.uppercased())
                    .font(.system(size: size * 0.07, weight: .heavy, design: .rounded))
                    .foregroundColor(instrument.isMuted ? .gray.opacity(0.4) : .white.opacity(0.85))
                    .lineLimit(1)
                
                Spacer()
                
                if instrument.hasActiveSteps && !instrument.isMuted {
                    Circle()
                        .fill(instrument.theme.primary)
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.horizontal, size * 0.08)
            .padding(.top, size * 0.06)
            
            Spacer()
            
            CircularPieSequencer(
                instrument: instrument,
                currentStep: audioEngine.currentStep,
                isPlaying: audioEngine.isPlaying,
                size: size * 0.7
            )
            
            Spacer()
        }
    }
}

// MARK: - Mini Circular Sequencer (for compact pads)

struct MiniCircularSequencer: View {
    let instrument: InstrumentPad
    let currentStep: Int
    let isPlaying: Bool
    let size: CGFloat
    
    private let stepCount = 8
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
            
            // Step segments
            ForEach(0..<stepCount, id: \.self) { step in
                MiniPieSegment(
                    step: step,
                    stepCount: stepCount,
                    isActive: instrument.steps[step].isActive,
                    isCurrent: isPlaying && step == currentStep,
                    isTriggering: isPlaying && step == currentStep && instrument.steps[step].isActive && !instrument.isMuted,
                    color: instrument.theme.primary,
                    isMuted: instrument.isMuted,
                    size: size
                )
            }
            
            // Inner circle
            Circle()
                .fill(Color(white: 0.08))
                .frame(width: size * 0.52, height: size * 0.52)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Mini Pie Segment

struct MiniPieSegment: View {
    let step: Int
    let stepCount: Int
    let isActive: Bool
    let isCurrent: Bool
    let isTriggering: Bool
    let color: Color
    let isMuted: Bool
    let size: CGFloat
    
    private let gapAngle: Double = 6
    
    var body: some View {
        let segmentSize = 360.0 / Double(stepCount)
        let startAngle = Angle(degrees: Double(step) * segmentSize - 90 + (gapAngle / 2))
        let endAngle = Angle(degrees: Double(step + 1) * segmentSize - 90 - (gapAngle / 2))
        
        ZStack {
            // Glow
            if isTriggering {
                PieSlice(
                    center: CGPoint(x: size / 2, y: size / 2),
                    innerRadius: size * 0.26,
                    outerRadius: size / 2 + 2,
                    startAngle: startAngle,
                    endAngle: endAngle
                )
                .fill(color)
                .blur(radius: 4)
                .opacity(0.7)
            }
            
            // Segment
            PieSlice(
                center: CGPoint(x: size / 2, y: size / 2),
                innerRadius: size * 0.26,
                outerRadius: size / 2 - 1,
                startAngle: startAngle,
                endAngle: endAngle
            )
            .fill(segmentColor)
            
            // Current step indicator
            if isCurrent && !isActive {
                PieSlice(
                    center: CGPoint(x: size / 2, y: size / 2),
                    innerRadius: size * 0.26,
                    outerRadius: size / 2 - 1,
                    startAngle: startAngle,
                    endAngle: endAngle
                )
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
            }
        }
        .frame(width: size, height: size)
        .animation(.easeOut(duration: 0.06), value: isCurrent)
    }
    
    private var segmentColor: Color {
        if isMuted {
            return isActive ? Color.gray.opacity(0.3) : Color.white.opacity(0.03)
        }
        if isTriggering {
            return color
        }
        if isActive {
            return color.opacity(0.7)
        }
        if isCurrent {
            return Color.white.opacity(0.12)
        }
        return Color.white.opacity(0.04)
    }
}

// MARK: - Circular Pie Sequencer (full size)

struct CircularPieSequencer: View {
    let instrument: InstrumentPad
    let currentStep: Int
    let isPlaying: Bool
    let size: CGFloat
    
    private let stepCount = 8
    private let gapAngle: Double = 4
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.3))
            
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 2)
            
            ForEach(0..<stepCount, id: \.self) { step in
                PieSegment(
                    startAngle: segmentStartAngle(for: step),
                    endAngle: segmentEndAngle(for: step),
                    isActive: instrument.steps[step].isActive,
                    isCurrent: isPlaying && step == currentStep,
                    isTriggering: isPlaying && step == currentStep && instrument.steps[step].isActive && !instrument.isMuted,
                    color: instrument.theme.primary,
                    isMuted: instrument.isMuted
                )
            }
            
            Circle()
                .fill(Color(white: 0.08))
                .frame(width: size * 0.42, height: size * 0.42)
            
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                .frame(width: size * 0.42, height: size * 0.42)
            
            centerContent
        }
        .frame(width: size, height: size)
    }
    
    private var centerContent: some View {
        let activeCount = instrument.steps.filter { $0.isActive }.count
        
        return VStack(spacing: 0) {
            if isPlaying && instrument.hasActiveSteps && !instrument.isMuted {
                Text("\(currentStep + 1)")
                    .font(.system(size: size * 0.18, weight: .black, design: .rounded))
                    .foregroundColor(instrument.theme.primary)
            } else {
                Text("\(activeCount)")
                    .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                    .foregroundColor(activeCount > 0 ? instrument.theme.primary.opacity(0.8) : .gray.opacity(0.3))
                
                if activeCount > 0 {
                    Text("STEPS")
                        .font(.system(size: size * 0.05, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
        }
    }
    
    private func segmentStartAngle(for step: Int) -> Angle {
        let segmentSize = 360.0 / Double(stepCount)
        return .degrees(Double(step) * segmentSize - 90 + (gapAngle / 2))
    }
    
    private func segmentEndAngle(for step: Int) -> Angle {
        let segmentSize = 360.0 / Double(stepCount)
        return .degrees(Double(step + 1) * segmentSize - 90 - (gapAngle / 2))
    }
}

// MARK: - Pie Segment

struct PieSegment: View {
    let startAngle: Angle
    let endAngle: Angle
    let isActive: Bool
    let isCurrent: Bool
    let isTriggering: Bool
    let color: Color
    let isMuted: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let outerRadius = size / 2 - 2
            let innerRadius = size * 0.21
            
            ZStack {
                if isTriggering {
                    PieSlice(
                        center: center,
                        innerRadius: innerRadius,
                        outerRadius: outerRadius + 4,
                        startAngle: startAngle,
                        endAngle: endAngle
                    )
                    .fill(color)
                    .blur(radius: 8)
                    .opacity(0.7)
                }
                
                PieSlice(
                    center: center,
                    innerRadius: innerRadius,
                    outerRadius: outerRadius,
                    startAngle: startAngle,
                    endAngle: endAngle
                )
                .fill(segmentColor)
                
                if isCurrent && !isActive {
                    PieSlice(
                        center: center,
                        innerRadius: innerRadius,
                        outerRadius: outerRadius,
                        startAngle: startAngle,
                        endAngle: endAngle
                    )
                    .stroke(Color.white.opacity(0.6), lineWidth: 2)
                }
                
                if isTriggering {
                    PieSlice(
                        center: center,
                        innerRadius: innerRadius + (outerRadius - innerRadius) * 0.3,
                        outerRadius: outerRadius - 2,
                        startAngle: startAngle,
                        endAngle: endAngle
                    )
                    .fill(Color.white.opacity(0.4))
                }
            }
        }
        .animation(.easeOut(duration: 0.08), value: isCurrent)
    }
    
    private var segmentColor: Color {
        if isMuted {
            return isActive ? Color.gray.opacity(0.35) : Color.white.opacity(0.05)
        }
        if isTriggering {
            return color
        }
        if isActive {
            return color.opacity(0.75)
        }
        if isCurrent {
            return Color.white.opacity(0.15)
        }
        return Color.white.opacity(0.06)
    }
}

// MARK: - Pie Slice Shape

struct PieSlice: Shape {
    let center: CGPoint
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let outerStart = CGPoint(
            x: center.x + outerRadius * CGFloat(cos(startAngle.radians)),
            y: center.y + outerRadius * CGFloat(sin(startAngle.radians))
        )
        
        path.move(to: outerStart)
        
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        path.addLine(to: CGPoint(
            x: center.x + innerRadius * CGFloat(cos(endAngle.radians)),
            y: center.y + innerRadius * CGFloat(sin(endAngle.radians))
        ))
        
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Sequencer Sheet

struct SequencerSheet: View {
    let instrument: InstrumentPad
    @ObservedObject var audioEngine: AudioEngineManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.1),
                    Color(red: 0.02, green: 0.02, blue: 0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                sheetHeader
                
                CircularPieSequencer(
                    instrument: instrument,
                    currentStep: audioEngine.currentStep,
                    isPlaying: audioEngine.isPlaying,
                    size: 160
                )
                .padding(.vertical, 4)
                
                stepGrid
                    .padding(.horizontal, 14)
                
                if !instrument.instrument.isDrum {
                    noteSelector
                        .padding(.horizontal, 14)
                }
                
                quickActions
                    .padding(.horizontal, 14)
                
                Spacer()
            }
            .padding(.top, 10)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var sheetHeader: some View {
        HStack {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [instrument.theme.primary.opacity(0.3), instrument.theme.primary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: instrument.instrument.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(instrument.theme.primary)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(instrument.instrument.rawValue.uppercased())
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(instrument.instrument.category.rawValue)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Button(action: {
                audioEngine.toggleMute(for: instrument.id)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }) {
                Image(systemName: instrument.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 13))
                    .foregroundColor(instrument.isMuted ? .red : .white)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(instrument.isMuted ? Color.red.opacity(0.2) : Color.white.opacity(0.1))
                    )
            }
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
        }
        .padding(.horizontal, 14)
    }
    
    private var stepGrid: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SEQUENCE")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
                .padding(.leading, 2)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(0..<8, id: \.self) { step in
                    StepButton(
                        step: step,
                        isActive: instrument.steps[step].isActive,
                        isCurrent: audioEngine.isPlaying && step == audioEngine.currentStep,
                        color: instrument.theme.primary,
                        onTap: {
                            audioEngine.toggleStep(step, for: instrument.id)
                            if !instrument.steps[step].isActive {
                                audioEngine.triggerInstrument(instrument.id, frequency: instrument.frequency(for: step))
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    private var noteSelector: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NOTES")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
                .padding(.leading, 2)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(0..<instrument.instrument.scaleFrequencies.count, id: \.self) { noteIndex in
                        NoteButton(noteIndex: noteIndex, color: instrument.theme.primary) {
                            for step in 0..<8 where instrument.steps[step].isActive {
                                audioEngine.setStepNote(step, for: instrument.id, noteIndex: noteIndex)
                            }
                            audioEngine.triggerInstrument(instrument.id, frequency: instrument.instrument.scaleFrequencies[noteIndex])
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    private var quickActions: some View {
        HStack(spacing: 8) {
            QuickButton(icon: "dice.fill", label: "Random", color: .yellow) {
                audioEngine.generateRandomPattern(for: instrument.id)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            
            QuickButton(icon: "trash.fill", label: "Clear", color: .red) {
                audioEngine.clearPattern(for: instrument.id)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            
            QuickButton(icon: "square.grid.2x2.fill", label: "Fill", color: instrument.theme.primary) {
                for step in 0..<8 where !instrument.steps[step].isActive {
                    audioEngine.toggleStep(step, for: instrument.id)
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }
}

// MARK: - Step Button

struct StepButton: View {
    let step: Int
    let isActive: Bool
    let isCurrent: Bool
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isActive && isCurrent {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .blur(radius: 10)
                        .scaleEffect(1.1)
                        .opacity(0.5)
                }
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isActive
                            ? LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.white.opacity(0.07), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isCurrent ? Color.white : (isActive ? color.opacity(0.4) : Color.white.opacity(0.08)),
                        lineWidth: isCurrent ? 2 : 0.5
                    )
                
                Text("\(step + 1)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(isActive ? .white : .gray.opacity(0.5))
            }
            .frame(height: 46)
        }
        .buttonStyle(.plain)
        .scaleEffect(isCurrent ? 1.03 : 1.0)
        .animation(.easeOut(duration: 0.08), value: isCurrent)
    }
}

// MARK: - Note Button

struct NoteButton: View {
    let noteIndex: Int
    let color: Color
    let onTap: () -> Void
    
    private let noteNames = ["C", "D", "E", "F", "G", "A", "B", "C'"]
    
    var body: some View {
        Button(action: onTap) {
            Text(noteIndex < noteNames.count ? noteNames[noteIndex] : "\(noteIndex + 1)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.25), lineWidth: 0.5))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Button

struct QuickButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                Text(label)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.2), lineWidth: 0.5))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Transport Bar

struct TransportBar: View {
    @ObservedObject var audioEngine: AudioEngineManager
    
    var body: some View {
        HStack(spacing: 8) {
            // Play/Stop
            Button(action: {
                audioEngine.togglePlayback()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(audioEngine.isPlaying ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                        .frame(width: 40, height: 32)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(audioEngine.isPlaying ? Color.red : Color.green, lineWidth: 1)
                        .frame(width: 40, height: 32)
                    
                    Image(systemName: audioEngine.isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(audioEngine.isPlaying ? .red : .green)
                }
            }
            
            // BPM
            HStack(spacing: 4) {
                Button(action: { audioEngine.setBPM(audioEngine.bpm - 5) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                
                VStack(spacing: -2) {
                    Text("\(Int(audioEngine.bpm))")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("BPM")
                        .font(.system(size: 5, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                }
                .frame(width: 36)
                
                Button(action: { audioEngine.setBPM(audioEngine.bpm + 5) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
            }
            
            Spacer()
            
            // Mini step indicator
            HStack(spacing: 2) {
                ForEach(0..<8, id: \.self) { step in
                    let hasActive = audioEngine.instruments.contains { $0.steps[step].isActive && !$0.isMuted }
                    RoundedRectangle(cornerRadius: 1)
                        .fill(stepColor(step: step, hasActive: hasActive))
                        .frame(width: 4, height: step % 2 == 0 ? 10 : 7)
                }
            }
            
            Spacer()
            
            // Random beat
            Button(action: {
                audioEngine.generateFullBeat()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }) {
                HStack(spacing: 2) {
                    Image(systemName: "dice.fill").font(.system(size: 9))
                    Text("GEN").font(.system(size: 7, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.yellow)
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.yellow.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.yellow.opacity(0.2), lineWidth: 0.5))
                )
            }
            
            // Clear all
            Button(action: {
                audioEngine.clearAllPatterns()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.red)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.red.opacity(0.1))
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.red.opacity(0.2), lineWidth: 0.5))
                    )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
        )
    }
    
    private func stepColor(step: Int, hasActive: Bool) -> Color {
        if audioEngine.isPlaying && audioEngine.currentStep == step {
            return hasActive ? .green : .green.opacity(0.5)
        }
        return hasActive ? Color.white.opacity(0.3) : Color.white.opacity(0.1)
    }
}

#Preview {
    ContentView()
}
