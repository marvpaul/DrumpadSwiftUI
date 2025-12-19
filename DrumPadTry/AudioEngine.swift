//
//  AudioEngine.swift
//  DrumPadTry
//
//  Created by Marvin Krüger on 18.12.25.
//

import Foundation
import Combine
import AudioKit
import AudioKitEX
import SoundpipeAudioKit
import AVFoundation

// MARK: - Sound Types

enum SynthType: String, CaseIterable, Sendable {
    case kick = "Kick"
    case snare = "Snare"
    case hihat = "HiHat"
    case bass = "Bass"
    case lead = "Lead"
    case pad = "Pad"
    case pluck = "Pluck"
    case fx = "FX"
}

enum TriggerMode: Sendable {
    case oneShot    // Play once when pressed
    case hold       // Play while held
    case toggle     // Toggle on/off
    case loop       // Loop synced to BPM
}

// MARK: - Sequencer Pattern

struct SequencerPattern: Identifiable {
    let id: Int  // Matches pad ID
    var steps: [Bool] = Array(repeating: false, count: 16)
    var frequency: Float = 440.0
    
    mutating func toggleStep(_ step: Int) {
        guard step >= 0 && step < 16 else { return }
        steps[step].toggle()
    }
}

// MARK: - Synth Voice

@MainActor
class SynthVoice {
    let oscillator: DynamicOscillator
    let envelope: AmplitudeEnvelope
    let filter: LowPassFilter
    
    var baseFrequency: Float = 440.0
    var isPlaying = false
    
    init(waveform: Table = Table(.sine)) {
        oscillator = DynamicOscillator(waveform: waveform)
        oscillator.amplitude = 0.5
        oscillator.frequency = 440.0
        
        filter = LowPassFilter(oscillator)
        filter.cutoffFrequency = 8000
        filter.resonance = 0.1
        
        envelope = AmplitudeEnvelope(filter)
        envelope.attackDuration = 0.01
        envelope.decayDuration = 0.1
        envelope.sustainLevel = 0.5
        envelope.releaseDuration = 0.3
    }
    
    var output: Node { envelope }
    
    func start() {
        oscillator.start()
    }
    
    func stop() {
        oscillator.stop()
    }
    
    func noteOn(frequency: Float) {
        oscillator.frequency = frequency
        envelope.openGate()
        isPlaying = true
    }
    
    func noteOff() {
        envelope.closeGate()
        isPlaying = false
    }
}

// MARK: - Drum Voice (for percussive sounds)

@MainActor
class DrumVoice {
    let oscillator: DynamicOscillator
    let noiseSource: WhiteNoise
    let oscEnvelope: AmplitudeEnvelope
    let noiseEnvelope: AmplitudeEnvelope
    let noiseBandpass: BandPassFilter
    let mixer: Mixer
    
    var pitchDecay: Float = 0.05
    var startPitch: Float = 150
    var endPitch: Float = 50
    
    init(type: SynthType) {
        // Oscillator path (for body of drums)
        oscillator = DynamicOscillator(waveform: Table(.sine))
        oscillator.amplitude = 0.8
        
        oscEnvelope = AmplitudeEnvelope(oscillator)
        
        // Noise path (for snare, hihats)
        noiseSource = WhiteNoise()
        noiseSource.amplitude = 0.3
        
        noiseBandpass = BandPassFilter(noiseSource)
        noiseBandpass.centerFrequency = 8000
        noiseBandpass.bandwidth = 4000
        
        noiseEnvelope = AmplitudeEnvelope(noiseBandpass)
        
        mixer = Mixer(oscEnvelope, noiseEnvelope)
        
        // Configure based on drum type
        configure(for: type)
    }
    
    var output: Node { mixer }
    
    func configure(for type: SynthType) {
        switch type {
        case .kick:
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.3
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.1
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.02
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.01
            startPitch = 150
            endPitch = 40
            pitchDecay = 0.05
            noiseSource.amplitude = 0.1
            oscillator.amplitude = 1.0
            
        case .snare:
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.1
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.05
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.15
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.1
            startPitch = 200
            endPitch = 120
            pitchDecay = 0.02
            noiseSource.amplitude = 0.5
            noiseBandpass.centerFrequency = 5000
            noiseBandpass.bandwidth = 6000
            
        case .hihat:
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.02
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.01
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.08
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.05
            noiseSource.amplitude = 0.6
            oscillator.amplitude = 0.1
            noiseBandpass.centerFrequency = 10000
            noiseBandpass.bandwidth = 5000
            
        default:
            break
        }
    }
    
    func start() {
        oscillator.start()
        noiseSource.start()
    }
    
    func stop() {
        oscillator.stop()
        noiseSource.stop()
    }
    
    func trigger() {
        let localStartPitch = startPitch
        let localEndPitch = endPitch
        let localPitchDecay = pitchDecay
        
        oscillator.frequency = localStartPitch
        oscEnvelope.openGate()
        noiseEnvelope.openGate()
        
        // Pitch envelope for kick drum effect
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let steps = 20
            let duration = localPitchDecay / Float(steps)
            let pitchStep = (localStartPitch - localEndPitch) / Float(steps)
            
            for i in 0..<steps {
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                self.oscillator.frequency = localStartPitch - (pitchStep * Float(i))
            }
            self.oscillator.frequency = localEndPitch
            
            self.oscEnvelope.closeGate()
            self.noiseEnvelope.closeGate()
        }
    }
}

// MARK: - Audio Engine Manager

@MainActor
class AudioEngineManager: ObservableObject {
    static let shared = AudioEngineManager()
    
    let engine = AudioEngine()
    private var mixer: Mixer!
    private var reverb: Reverb!
    
    // Synth voices for melodic sounds
    private var synthVoices: [Int: SynthVoice] = [:]
    private var drumVoices: [Int: DrumVoice] = [:]
    
    // Active toggle states
    @Published var activeToggles: Set<Int> = []
    
    // BPM and transport
    @Published var bpm: Double = 120.0
    @Published var isPlaying: Bool = false
    @Published var currentBeat: Int = 0
    
    // Sequencer
    @Published var patterns: [Int: SequencerPattern] = [:]
    @Published var selectedPadForSequencer: Int? = nil
    @Published var isSequencerMode: Bool = false
    
    private var beatTimer: Timer?
    
    // Store frequencies for each pad
    private var padFrequencies: [Int: Float] = [:]
    
    private init() {
        setupAudio()
    }
    
    private func setupAudio() {
        mixer = Mixer()
        
        reverb = Reverb(mixer)
        reverb.dryWetMix = 0.2
        
        engine.output = reverb
        
        do {
            try engine.start()
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }
    
    func createVoice(for padId: Int, type: SynthType, frequency: Float = 440.0) {
        padFrequencies[padId] = frequency
        
        // Initialize empty pattern for this pad
        if patterns[padId] == nil {
            patterns[padId] = SequencerPattern(id: padId, frequency: frequency)
        }
        
        switch type {
        case .kick, .snare, .hihat:
            let drumVoice = DrumVoice(type: type)
            drumVoices[padId] = drumVoice
            mixer.addInput(drumVoice.output)
            drumVoice.start()
            
        case .bass:
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.01
            voice.envelope.decayDuration = 0.2
            voice.envelope.sustainLevel = 0.6
            voice.envelope.releaseDuration = 0.2
            voice.filter.cutoffFrequency = 2000
            synthVoices[padId] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .lead:
            let voice = SynthVoice(waveform: Table(.square))
            voice.envelope.attackDuration = 0.05
            voice.envelope.decayDuration = 0.1
            voice.envelope.sustainLevel = 0.7
            voice.envelope.releaseDuration = 0.3
            voice.filter.cutoffFrequency = 4000
            synthVoices[padId] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .pad:
            let voice = SynthVoice(waveform: Table(.sine))
            voice.envelope.attackDuration = 0.3
            voice.envelope.decayDuration = 0.5
            voice.envelope.sustainLevel = 0.8
            voice.envelope.releaseDuration = 1.0
            voice.filter.cutoffFrequency = 3000
            synthVoices[padId] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .pluck:
            let voice = SynthVoice(waveform: Table(.triangle))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.3
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.1
            voice.filter.cutoffFrequency = 6000
            synthVoices[padId] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .fx:
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.1
            voice.envelope.decayDuration = 0.5
            voice.envelope.sustainLevel = 0.3
            voice.envelope.releaseDuration = 0.8
            voice.filter.cutoffFrequency = 1500
            voice.filter.resonance = 0.5
            synthVoices[padId] = voice
            mixer.addInput(voice.output)
            voice.start()
        }
    }
    
    func triggerPad(_ padId: Int, frequency: Float = 440.0) {
        if let drumVoice = drumVoices[padId] {
            drumVoice.trigger()
        } else if let synthVoice = synthVoices[padId] {
            synthVoice.noteOn(frequency: frequency)
            // Auto-release for pluck sounds
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000)
                synthVoice.noteOff()
            }
        }
    }
    
    func releasePad(_ padId: Int) {
        if let synthVoice = synthVoices[padId] {
            synthVoice.noteOff()
        }
    }
    
    func togglePad(_ padId: Int, frequency: Float = 440.0) {
        if activeToggles.contains(padId) {
            activeToggles.remove(padId)
            releasePad(padId)
        } else {
            activeToggles.insert(padId)
            triggerPad(padId, frequency: frequency)
        }
    }
    
    // MARK: - Sequencer
    
    func selectPadForSequencer(_ padId: Int) {
        if selectedPadForSequencer == padId {
            selectedPadForSequencer = nil
            isSequencerMode = false
        } else {
            selectedPadForSequencer = padId
            isSequencerMode = true
        }
    }
    
    func toggleStep(_ step: Int, forPad padId: Int) {
        patterns[padId]?.toggleStep(step)
    }
    
    func hasPattern(_ padId: Int) -> Bool {
        guard let pattern = patterns[padId] else { return false }
        return pattern.steps.contains(true)
    }
    
    func clearPattern(_ padId: Int) {
        patterns[padId]?.steps = Array(repeating: false, count: 16)
    }
    
    func clearAllPatterns() {
        for key in patterns.keys {
            patterns[key]?.steps = Array(repeating: false, count: 16)
        }
    }
    
    // MARK: - BPM Control
    
    func startBeat() {
        isPlaying = true
        currentBeat = 0
        let interval = 60.0 / bpm / 4.0 // 16th notes
        
        beatTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // Trigger all sounds that have this step enabled
                for (padId, pattern) in self.patterns {
                    if pattern.steps[self.currentBeat] {
                        let freq = self.padFrequencies[padId] ?? 440.0
                        self.triggerPad(padId, frequency: freq)
                    }
                }
                
                self.currentBeat = (self.currentBeat + 1) % 16
            }
        }
    }
    
    func stopBeat() {
        isPlaying = false
        beatTimer?.invalidate()
        beatTimer = nil
        currentBeat = 0
    }
    
    func setBPM(_ newBPM: Double) {
        bpm = max(60, min(200, newBPM))
        if isPlaying {
            stopBeat()
            startBeat()
        }
    }
}
