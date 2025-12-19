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
        oscillator.amplitude = 0.4
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

// MARK: - Drum Voice

@MainActor
class DrumVoice {
    let oscillator: DynamicOscillator
    let oscillator2: DynamicOscillator  // Second oscillator for layering
    let noiseSource: WhiteNoise
    let pinkNoise: PinkNoise  // Additional noise color
    let oscEnvelope: AmplitudeEnvelope
    let osc2Envelope: AmplitudeEnvelope
    let noiseEnvelope: AmplitudeEnvelope
    let noiseBandpass: BandPassFilter
    let noiseHighpass: HighPassFilter
    let mixer: Mixer
    
    var pitchDecay: Float = 0.05
    var startPitch: Float = 150
    var endPitch: Float = 50
    var pitch2Start: Float = 300
    var pitch2End: Float = 200
    var usePinkNoise: Bool = false
    var useSecondOsc: Bool = false
    
    init(type: InstrumentType) {
        oscillator = DynamicOscillator(waveform: Table(.sine))
        oscillator.amplitude = 0.7
        
        oscillator2 = DynamicOscillator(waveform: Table(.triangle))
        oscillator2.amplitude = 0.3
        
        oscEnvelope = AmplitudeEnvelope(oscillator)
        osc2Envelope = AmplitudeEnvelope(oscillator2)
        
        noiseSource = WhiteNoise()
        noiseSource.amplitude = 0.3
        
        pinkNoise = PinkNoise()
        pinkNoise.amplitude = 0.0
        
        let noiseMixer = Mixer(noiseSource, pinkNoise)
        
        noiseBandpass = BandPassFilter(noiseMixer)
        noiseBandpass.centerFrequency = 8000
        noiseBandpass.bandwidth = 4000
        
        noiseHighpass = HighPassFilter(noiseBandpass)
        noiseHighpass.cutoffFrequency = 100
        
        noiseEnvelope = AmplitudeEnvelope(noiseHighpass)
        
        mixer = Mixer(oscEnvelope, osc2Envelope, noiseEnvelope)
        
        configure(for: type)
    }
    
    var output: Node { mixer }
    
    func configure(for type: InstrumentType) {
        switch type {
        // === KICKS - Deep thumpy sounds ===
        case .kick:
            // Classic 808-style deep kick
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.4
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.15
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.015
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.01
            startPitch = 180
            endPitch = 35
            pitchDecay = 0.08
            noiseSource.amplitude = 0.15
            oscillator.amplitude = 1.0
            noiseBandpass.centerFrequency = 3000
            noiseBandpass.bandwidth = 2000
            
        case .kick2:
            // Punchy techno kick - shorter, more attack
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.18
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.05
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.008
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.005
            startPitch = 250
            endPitch = 45
            pitchDecay = 0.025
            noiseSource.amplitude = 0.25
            oscillator.amplitude = 0.95
            noiseBandpass.centerFrequency = 4500
            noiseBandpass.bandwidth = 3000
            noiseHighpass.cutoffFrequency = 500
            
        // === SNARES - Crispy and snappy ===
        case .snare:
            // Classic acoustic-style snare
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.12
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.06
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.18
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.12
            startPitch = 220
            endPitch = 140
            pitchDecay = 0.015
            noiseSource.amplitude = 0.55
            oscillator.amplitude = 0.5
            noiseBandpass.centerFrequency = 4500
            noiseBandpass.bandwidth = 5000
            noiseHighpass.cutoffFrequency = 1200
            
        case .snare2:
            // Tight electronic snare - more snap, less body
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.05
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.02
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.08
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.06
            startPitch = 350
            endPitch = 180
            pitchDecay = 0.008
            noiseSource.amplitude = 0.75
            oscillator.amplitude = 0.35
            noiseBandpass.centerFrequency = 7000
            noiseBandpass.bandwidth = 4000
            noiseHighpass.cutoffFrequency = 2500
            
        case .rimshot:
            // Sharp metallic rim hit
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.035
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.015
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.025
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.015
            startPitch = 1200
            endPitch = 850
            pitchDecay = 0.005
            noiseSource.amplitude = 0.4
            oscillator.amplitude = 0.55
            noiseBandpass.centerFrequency = 6000
            noiseBandpass.bandwidth = 3000
            noiseHighpass.cutoffFrequency = 2000
            
        case .clap:
            // Multi-layered clap with flutter
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.04
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.02
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.22
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.18
            noiseSource.amplitude = 0.8
            oscillator.amplitude = 0.15
            noiseBandpass.centerFrequency = 1800
            noiseBandpass.bandwidth = 2500
            noiseHighpass.cutoffFrequency = 800
            startPitch = 500
            endPitch = 300
            pitchDecay = 0.01
            
        case .snap:
            // High finger snap - very short and bright
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.02
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.01
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.04
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.025
            startPitch = 2800
            endPitch = 2200
            pitchDecay = 0.004
            noiseSource.amplitude = 0.5
            oscillator.amplitude = 0.45
            noiseBandpass.centerFrequency = 5500
            noiseBandpass.bandwidth = 2000
            noiseHighpass.cutoffFrequency = 3000
            
        case .tom:
            // Deep floor tom
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.28
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.12
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.04
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.025
            startPitch = 160
            endPitch = 75
            pitchDecay = 0.04
            noiseSource.amplitude = 0.2
            oscillator.amplitude = 0.85
            noiseBandpass.centerFrequency = 2500
            noiseBandpass.bandwidth = 2000
            
        // === HI-HATS - Metallic textures ===
        case .hihatClosed:
            // Tight closed hihat
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.015
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.008
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.045
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.02
            noiseSource.amplitude = 0.55
            oscillator.amplitude = 0.18
            startPitch = 12000
            endPitch = 9000
            pitchDecay = 0.003
            noiseBandpass.centerFrequency = 11000
            noiseBandpass.bandwidth = 4000
            noiseHighpass.cutoffFrequency = 6000
            
        case .hihatOpen:
            // Sizzling open hihat
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.03
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.015
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.35
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.2
            noiseSource.amplitude = 0.5
            oscillator.amplitude = 0.15
            startPitch = 10000
            endPitch = 7000
            pitchDecay = 0.01
            noiseBandpass.centerFrequency = 9000
            noiseBandpass.bandwidth = 6000
            noiseHighpass.cutoffFrequency = 4000
            
        case .hihatPedal:
            // Chunky pedal hihat
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.01
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.005
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.025
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.015
            noiseSource.amplitude = 0.45
            oscillator.amplitude = 0.12
            startPitch = 8000
            endPitch = 6000
            pitchDecay = 0.002
            noiseBandpass.centerFrequency = 7500
            noiseBandpass.bandwidth = 3000
            noiseHighpass.cutoffFrequency = 4500
            
        // === CYMBALS - Long sustaining ===
        case .crash:
            // Explosive crash cymbal
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.02
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.01
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.7
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.4
            noiseSource.amplitude = 0.7
            oscillator.amplitude = 0.12
            startPitch = 8000
            endPitch = 5000
            pitchDecay = 0.02
            noiseBandpass.centerFrequency = 6500
            noiseBandpass.bandwidth = 8000
            noiseHighpass.cutoffFrequency = 2000
            
        case .ride:
            // Sustained ride with ping
            useSecondOsc = true
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.05
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.02
            osc2Envelope.attackDuration = 0.001
            osc2Envelope.decayDuration = 0.5
            osc2Envelope.sustainLevel = 0.0
            osc2Envelope.releaseDuration = 0.2
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.55
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.25
            noiseSource.amplitude = 0.35
            oscillator.amplitude = 0.25
            oscillator2.amplitude = 0.35
            startPitch = 5500
            endPitch = 4800
            pitch2Start = 3200
            pitch2End = 3000
            pitchDecay = 0.015
            noiseBandpass.centerFrequency = 5500
            noiseBandpass.bandwidth = 4500
            noiseHighpass.cutoffFrequency = 2500
            
        case .china:
            // Trashy china cymbal
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.015
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.008
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.45
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.25
            noiseSource.amplitude = 0.65
            oscillator.amplitude = 0.1
            startPitch = 3500
            endPitch = 2800
            pitchDecay = 0.008
            noiseBandpass.centerFrequency = 3800
            noiseBandpass.bandwidth = 5000
            noiseHighpass.cutoffFrequency = 1500
            
        case .splash:
            // Quick splash cymbal
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.015
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.008
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.25
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.15
            noiseSource.amplitude = 0.55
            oscillator.amplitude = 0.15
            startPitch = 9000
            endPitch = 7000
            pitchDecay = 0.008
            noiseBandpass.centerFrequency = 8000
            noiseBandpass.bandwidth = 6000
            noiseHighpass.cutoffFrequency = 4000
            
        case .bell:
            // Clear bell tone
            useSecondOsc = true
            oscillator2.setWaveform(Table(.sine))
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.6
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.3
            osc2Envelope.attackDuration = 0.001
            osc2Envelope.decayDuration = 0.45
            osc2Envelope.sustainLevel = 0.0
            osc2Envelope.releaseDuration = 0.25
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.06
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.03
            noiseSource.amplitude = 0.1
            oscillator.amplitude = 0.55
            oscillator2.amplitude = 0.4
            startPitch = 3500
            endPitch = 3400
            pitch2Start = 5600
            pitch2End = 5500
            pitchDecay = 0.015
            noiseBandpass.centerFrequency = 8000
            
        // === PERCUSSION - World instruments ===
        case .conga:
            // Deep hand drum
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.22
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.1
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.018
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.01
            startPitch = 320
            endPitch = 210
            pitchDecay = 0.025
            noiseSource.amplitude = 0.18
            oscillator.amplitude = 0.8
            noiseBandpass.centerFrequency = 2200
            
        case .bongo:
            // High pitched bongo
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.1
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.05
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.012
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.008
            startPitch = 520
            endPitch = 400
            pitchDecay = 0.012
            noiseSource.amplitude = 0.15
            oscillator.amplitude = 0.75
            noiseBandpass.centerFrequency = 3500
            
        case .shaker:
            // Rhythmic shaker - mostly noise
            usePinkNoise = true
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.005
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.003
            noiseEnvelope.attackDuration = 0.002
            noiseEnvelope.decayDuration = 0.08
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.06
            noiseSource.amplitude = 0.35
            pinkNoise.amplitude = 0.25
            oscillator.amplitude = 0.02
            noiseBandpass.centerFrequency = 12000
            noiseBandpass.bandwidth = 5000
            noiseHighpass.cutoffFrequency = 7000
            
        case .tambourine:
            // Jingly tambourine
            useSecondOsc = true
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.03
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.015
            osc2Envelope.attackDuration = 0.001
            osc2Envelope.decayDuration = 0.12
            osc2Envelope.sustainLevel = 0.0
            osc2Envelope.releaseDuration = 0.08
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.14
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.1
            noiseSource.amplitude = 0.5
            oscillator.amplitude = 0.12
            oscillator2.amplitude = 0.15
            startPitch = 8500
            pitch2Start = 11000
            pitch2End = 10500
            endPitch = 7500
            pitchDecay = 0.008
            noiseBandpass.centerFrequency = 9500
            noiseBandpass.bandwidth = 4500
            noiseHighpass.cutoffFrequency = 5500
            
        case .cowbell:
            // Classic 808 cowbell - two tone
            useSecondOsc = true
            oscillator.setWaveform(Table(.square))
            oscillator2.setWaveform(Table(.square))
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.2
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.08
            osc2Envelope.attackDuration = 0.001
            osc2Envelope.decayDuration = 0.18
            osc2Envelope.sustainLevel = 0.0
            osc2Envelope.releaseDuration = 0.06
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.015
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.008
            startPitch = 587
            endPitch = 580
            pitch2Start = 845
            pitch2End = 840
            pitchDecay = 0.008
            noiseSource.amplitude = 0.08
            oscillator.amplitude = 0.5
            oscillator2.amplitude = 0.4
            
        case .woodblock:
            // Sharp wood hit
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.045
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.02
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.015
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.008
            startPitch = 2200
            endPitch = 1850
            pitchDecay = 0.006
            noiseSource.amplitude = 0.25
            oscillator.amplitude = 0.6
            noiseBandpass.centerFrequency = 4000
            noiseBandpass.bandwidth = 2000
            noiseHighpass.cutoffFrequency = 1500
            
        case .triangle:
            // Shimmering triangle
            useSecondOsc = true
            oscillator.setWaveform(Table(.sine))
            oscillator2.setWaveform(Table(.sine))
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.8
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.5
            osc2Envelope.attackDuration = 0.001
            osc2Envelope.decayDuration = 0.65
            osc2Envelope.sustainLevel = 0.0
            osc2Envelope.releaseDuration = 0.4
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.015
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.008
            startPitch = 4500
            endPitch = 4450
            pitch2Start = 9000
            pitch2End = 8950
            pitchDecay = 0.01
            noiseSource.amplitude = 0.04
            oscillator.amplitude = 0.45
            oscillator2.amplitude = 0.25
            
        case .agogo:
            // Bright agogo bell
            useSecondOsc = true
            oscillator.setWaveform(Table(.sine))
            oscillator2.setWaveform(Table(.sine))
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.25
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.12
            osc2Envelope.attackDuration = 0.001
            osc2Envelope.decayDuration = 0.22
            osc2Envelope.sustainLevel = 0.0
            osc2Envelope.releaseDuration = 0.1
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.012
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.006
            startPitch = 780
            endPitch = 760
            pitch2Start = 1230
            pitch2End = 1210
            pitchDecay = 0.008
            noiseSource.amplitude = 0.08
            oscillator.amplitude = 0.55
            oscillator2.amplitude = 0.35
            
        default:
            // Default drum settings
            oscEnvelope.attackDuration = 0.001
            oscEnvelope.decayDuration = 0.15
            oscEnvelope.sustainLevel = 0.0
            oscEnvelope.releaseDuration = 0.08
            noiseEnvelope.attackDuration = 0.001
            noiseEnvelope.decayDuration = 0.1
            noiseEnvelope.sustainLevel = 0.0
            noiseEnvelope.releaseDuration = 0.05
            noiseSource.amplitude = 0.3
            oscillator.amplitude = 0.5
        }
    }
    
    func start() {
        oscillator.start()
        oscillator2.start()
        noiseSource.start()
        pinkNoise.start()
    }
    
    func stop() {
        oscillator.stop()
        oscillator2.stop()
        noiseSource.stop()
        pinkNoise.stop()
    }
    
    func trigger() {
        let localStartPitch = startPitch
        let localEndPitch = endPitch
        let localPitchDecay = pitchDecay
        let localPitch2Start = pitch2Start
        let localPitch2End = pitch2End
        let localUseSecondOsc = useSecondOsc
        
        oscillator.frequency = localStartPitch
        if localUseSecondOsc {
            oscillator2.frequency = localPitch2Start
            osc2Envelope.openGate()
        }
        oscEnvelope.openGate()
        noiseEnvelope.openGate()
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let steps = 20
            let duration = localPitchDecay / Float(steps)
            let pitchStep = (localStartPitch - localEndPitch) / Float(steps)
            let pitch2Step = (localPitch2Start - localPitch2End) / Float(steps)
            
            for i in 0..<steps {
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                self.oscillator.frequency = localStartPitch - (pitchStep * Float(i))
                if localUseSecondOsc {
                    self.oscillator2.frequency = localPitch2Start - (pitch2Step * Float(i))
                }
            }
            self.oscillator.frequency = localEndPitch
            if localUseSecondOsc {
                self.oscillator2.frequency = localPitch2End
            }
            
            self.oscEnvelope.closeGate()
            if localUseSecondOsc {
                self.osc2Envelope.closeGate()
            }
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
    
    private var synthVoices: [Int: SynthVoice] = [:]
    private var drumVoices: [Int: DrumVoice] = [:]
    
    @Published var bpm: Double = 120.0
    @Published var isPlaying: Bool = false
    @Published var currentStep: Int = 0
    
    @Published var instruments: [InstrumentPad] = []
    
    private var beatTimer: Timer?
    private let stepCount = 8
    
    private init() {
        setupAudio()
    }
    
    private func setupAudio() {
        mixer = Mixer()
        
        reverb = Reverb(mixer)
        reverb.dryWetMix = 0.15
        
        engine.output = reverb
        
        do {
            try engine.start()
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }
    
    func initializeInstruments() {
        instruments = InstrumentPad.defaultInstruments()
        
        for instrument in instruments {
            createVoice(for: instrument)
        }
    }
    
    private func createVoice(for instrument: InstrumentPad) {
        let type = instrument.instrument
        
        // Drums, cymbals, percussion use drum voices
        if type.isDrum {
            let drumVoice = DrumVoice(type: type)
            drumVoices[instrument.id] = drumVoice
            mixer.addInput(drumVoice.output)
            drumVoice.start()
            return
        }
        
        // Synth instruments - each with VERY distinct characteristics
        switch type {
        // === BASS SOUNDS ===
        case .bass:
            // Classic round bass - pure sine sub with warmth
            let voice = SynthVoice(waveform: Table(.sine))
            voice.envelope.attackDuration = 0.005
            voice.envelope.decayDuration = 0.2
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.12
            voice.filter.cutoffFrequency = 600
            voice.filter.resonance = 0.05
            voice.oscillator.amplitude = 0.65
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .bass2:
            // Growling bass - sawtooth with grit
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.18
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.1
            voice.filter.cutoffFrequency = 1800
            voice.filter.resonance = 0.15
            voice.oscillator.amplitude = 0.55
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .subBass:
            // Ultra deep sub - pure low sine
            let voice = SynthVoice(waveform: Table(.sine))
            voice.envelope.attackDuration = 0.008
            voice.envelope.decayDuration = 0.35
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.2
            voice.filter.cutoffFrequency = 280
            voice.filter.resonance = 0.0
            voice.oscillator.amplitude = 0.75
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .acidBass:
            // Classic 303 acid - squelchy resonant
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.12
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.08
            voice.filter.cutoffFrequency = 3500
            voice.filter.resonance = 0.65
            voice.oscillator.amplitude = 0.5
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .pluckBass:
            // Snappy pluck bass - fast attack/decay
            let voice = SynthVoice(waveform: Table(.triangle))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.06
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.04
            voice.filter.cutoffFrequency = 2200
            voice.filter.resonance = 0.25
            voice.oscillator.amplitude = 0.6
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .wobble:
            // Dubstep wobble - thick and sustained
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.015
            voice.envelope.decayDuration = 0.4
            voice.envelope.sustainLevel = 0.3
            voice.envelope.releaseDuration = 0.2
            voice.filter.cutoffFrequency = 900
            voice.filter.resonance = 0.35
            voice.oscillator.amplitude = 0.6
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .reese:
            // Detuned reese bass - thick drone
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.02
            voice.envelope.decayDuration = 0.3
            voice.envelope.sustainLevel = 0.2
            voice.envelope.releaseDuration = 0.15
            voice.filter.cutoffFrequency = 1400
            voice.filter.resonance = 0.12
            voice.oscillator.amplitude = 0.55
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .fmBass:
            // FM-style metallic bass
            let voice = SynthVoice(waveform: Table(.square))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.14
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.08
            voice.filter.cutoffFrequency = 2800
            voice.filter.resonance = 0.2
            voice.oscillator.amplitude = 0.45
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        // === LEAD SOUNDS ===
        case .lead:
            // Classic mono lead - bright and cutting
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.008
            voice.envelope.decayDuration = 0.25
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.15
            voice.filter.cutoffFrequency = 5500
            voice.filter.resonance = 0.1
            voice.oscillator.amplitude = 0.45
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .lead2:
            // Soft lead - warmer, rounder
            let voice = SynthVoice(waveform: Table(.triangle))
            voice.envelope.attackDuration = 0.02
            voice.envelope.decayDuration = 0.3
            voice.envelope.sustainLevel = 0.15
            voice.envelope.releaseDuration = 0.2
            voice.filter.cutoffFrequency = 3200
            voice.filter.resonance = 0.08
            voice.oscillator.amplitude = 0.5
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .saw:
            // Pure sawtooth - raw and aggressive
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.15
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.1
            voice.filter.cutoffFrequency = 8000
            voice.filter.resonance = 0.0
            voice.oscillator.amplitude = 0.4
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .square:
            // Hollow square - retro 8-bit feel
            let voice = SynthVoice(waveform: Table(.square))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.18
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.12
            voice.filter.cutoffFrequency = 4500
            voice.filter.resonance = 0.05
            voice.oscillator.amplitude = 0.35
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .supersaw:
            // Big supersaw - massive and wide
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.015
            voice.envelope.decayDuration = 0.35
            voice.envelope.sustainLevel = 0.1
            voice.envelope.releaseDuration = 0.25
            voice.filter.cutoffFrequency = 7500
            voice.filter.resonance = 0.08
            voice.oscillator.amplitude = 0.5
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .hoover:
            // Classic hoover - nasty and wide
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.01
            voice.envelope.decayDuration = 0.28
            voice.envelope.sustainLevel = 0.05
            voice.envelope.releaseDuration = 0.18
            voice.filter.cutoffFrequency = 4200
            voice.filter.resonance = 0.18
            voice.oscillator.amplitude = 0.5
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .sync:
            // Hard sync sound - harsh and biting
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.12
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.08
            voice.filter.cutoffFrequency = 6500
            voice.filter.resonance = 0.35
            voice.oscillator.amplitude = 0.42
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .formant:
            // Vowel-like formant - human quality
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.02
            voice.envelope.decayDuration = 0.22
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.15
            voice.filter.cutoffFrequency = 1800
            voice.filter.resonance = 0.45
            voice.oscillator.amplitude = 0.48
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        // === PAD SOUNDS ===
        case .pad:
            // Warm analog pad - smooth and full
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.15
            voice.envelope.decayDuration = 0.4
            voice.envelope.sustainLevel = 0.45
            voice.envelope.releaseDuration = 0.6
            voice.filter.cutoffFrequency = 2200
            voice.filter.resonance = 0.08
            voice.oscillator.amplitude = 0.38
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .pad2:
            // Digital pad - cleaner, more defined
            let voice = SynthVoice(waveform: Table(.triangle))
            voice.envelope.attackDuration = 0.12
            voice.envelope.decayDuration = 0.35
            voice.envelope.sustainLevel = 0.5
            voice.envelope.releaseDuration = 0.5
            voice.filter.cutoffFrequency = 3500
            voice.filter.resonance = 0.05
            voice.oscillator.amplitude = 0.4
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .strings:
            // Orchestral strings - rich and evolving
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.25
            voice.envelope.decayDuration = 0.5
            voice.envelope.sustainLevel = 0.55
            voice.envelope.releaseDuration = 0.7
            voice.filter.cutoffFrequency = 3800
            voice.filter.resonance = 0.04
            voice.oscillator.amplitude = 0.4
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .choir:
            // Ethereal choir - airy and vocal
            let voice = SynthVoice(waveform: Table(.sine))
            voice.envelope.attackDuration = 0.2
            voice.envelope.decayDuration = 0.45
            voice.envelope.sustainLevel = 0.4
            voice.envelope.releaseDuration = 0.65
            voice.filter.cutoffFrequency = 1600
            voice.filter.resonance = 0.2
            voice.oscillator.amplitude = 0.42
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .ambient:
            // Spacey ambient - slow and atmospheric
            let voice = SynthVoice(waveform: Table(.sine))
            voice.envelope.attackDuration = 0.4
            voice.envelope.decayDuration = 0.6
            voice.envelope.sustainLevel = 0.35
            voice.envelope.releaseDuration = 1.2
            voice.filter.cutoffFrequency = 2800
            voice.filter.resonance = 0.1
            voice.oscillator.amplitude = 0.35
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .sweep:
            // Filter sweep pad - moving texture
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.35
            voice.envelope.decayDuration = 0.5
            voice.envelope.sustainLevel = 0.3
            voice.envelope.releaseDuration = 0.55
            voice.filter.cutoffFrequency = 4500
            voice.filter.resonance = 0.25
            voice.oscillator.amplitude = 0.4
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .drone:
            // Deep drone - sustaining foundation
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.3
            voice.envelope.decayDuration = 0.8
            voice.envelope.sustainLevel = 0.6
            voice.envelope.releaseDuration = 1.5
            voice.filter.cutoffFrequency = 1200
            voice.filter.resonance = 0.15
            voice.oscillator.amplitude = 0.45
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .texture:
            // Granular texture - complex and evolving
            let voice = SynthVoice(waveform: Table(.square))
            voice.envelope.attackDuration = 0.18
            voice.envelope.decayDuration = 0.4
            voice.envelope.sustainLevel = 0.35
            voice.envelope.releaseDuration = 0.6
            voice.filter.cutoffFrequency = 3200
            voice.filter.resonance = 0.18
            voice.oscillator.amplitude = 0.32
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        // === ARPS & PLUCKS ===
        case .arp:
            // Bright arp - quick and sparkly
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.08
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.04
            voice.filter.cutoffFrequency = 7000
            voice.filter.resonance = 0.12
            voice.oscillator.amplitude = 0.42
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .arp2:
            // Softer arp - rounder plucks
            let voice = SynthVoice(waveform: Table(.triangle))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.12
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.06
            voice.filter.cutoffFrequency = 4500
            voice.filter.resonance = 0.08
            voice.oscillator.amplitude = 0.45
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .pluck:
            // Generic pluck - versatile
            let voice = SynthVoice(waveform: Table(.triangle))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.15
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.08
            voice.filter.cutoffFrequency = 5200
            voice.filter.resonance = 0.15
            voice.oscillator.amplitude = 0.45
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .marimba:
            // Wooden marimba - mellow and warm
            let voice = SynthVoice(waveform: Table(.sine))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.25
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.12
            voice.filter.cutoffFrequency = 3200
            voice.filter.resonance = 0.02
            voice.oscillator.amplitude = 0.55
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .vibes:
            // Vibraphone - metallic and sustaining
            let voice = SynthVoice(waveform: Table(.sine))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.5
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.35
            voice.filter.cutoffFrequency = 5800
            voice.filter.resonance = 0.05
            voice.oscillator.amplitude = 0.48
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .bells:
            // Crystal bells - shimmering high
            let voice = SynthVoice(waveform: Table(.sine))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.75
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.5
            voice.filter.cutoffFrequency = 12000
            voice.filter.resonance = 0.02
            voice.oscillator.amplitude = 0.4
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .keys:
            // Electric piano keys - warm and rounded
            let voice = SynthVoice(waveform: Table(.sine))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.35
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.18
            voice.filter.cutoffFrequency = 4200
            voice.filter.resonance = 0.08
            voice.oscillator.amplitude = 0.5
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .piano:
            // Acoustic piano - rich harmonics
            let voice = SynthVoice(waveform: Table(.triangle))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.4
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.25
            voice.filter.cutoffFrequency = 6500
            voice.filter.resonance = 0.04
            voice.oscillator.amplitude = 0.52
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        // === FX SOUNDS ===
        case .riser:
            // Tension riser - building energy
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.6
            voice.envelope.decayDuration = 0.8
            voice.envelope.sustainLevel = 0.6
            voice.envelope.releaseDuration = 0.3
            voice.filter.cutoffFrequency = 6000
            voice.filter.resonance = 0.2
            voice.oscillator.amplitude = 0.45
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .downlift:
            // Energy release - falling sweep
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.5
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.25
            voice.filter.cutoffFrequency = 8000
            voice.filter.resonance = 0.25
            voice.oscillator.amplitude = 0.5
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .impact:
            // Heavy impact - punchy low hit
            let voice = SynthVoice(waveform: Table(.sine))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.6
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.3
            voice.filter.cutoffFrequency = 800
            voice.filter.resonance = 0.1
            voice.oscillator.amplitude = 0.7
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .noise:
            // Filtered noise sweep
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.02
            voice.envelope.decayDuration = 0.35
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.2
            voice.filter.cutoffFrequency = 9000
            voice.filter.resonance = 0.4
            voice.oscillator.amplitude = 0.35
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .glitch:
            // Digital glitch - short and choppy
            let voice = SynthVoice(waveform: Table(.square))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.03
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.015
            voice.filter.cutoffFrequency = 7500
            voice.filter.resonance = 0.3
            voice.oscillator.amplitude = 0.4
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .stab:
            // Brass stab - punchy chord hit
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.001
            voice.envelope.decayDuration = 0.1
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.06
            voice.filter.cutoffFrequency = 5500
            voice.filter.resonance = 0.15
            voice.oscillator.amplitude = 0.55
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .vox:
            // Vocal-like synth - formant resonance
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.03
            voice.envelope.decayDuration = 0.3
            voice.envelope.sustainLevel = 0.2
            voice.envelope.releaseDuration = 0.2
            voice.filter.cutoffFrequency = 2200
            voice.filter.resonance = 0.5
            voice.oscillator.amplitude = 0.45
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        case .fx:
            // Generic FX - versatile effect
            let voice = SynthVoice(waveform: Table(.sawtooth))
            voice.envelope.attackDuration = 0.01
            voice.envelope.decayDuration = 0.25
            voice.envelope.sustainLevel = 0.0
            voice.envelope.releaseDuration = 0.15
            voice.filter.cutoffFrequency = 5000
            voice.filter.resonance = 0.2
            voice.oscillator.amplitude = 0.45
            synthVoices[instrument.id] = voice
            mixer.addInput(voice.output)
            voice.start()
            
        default:
            break
        }
    }
    
    // MARK: - Playback
    
    func triggerInstrument(_ instrumentId: Int, frequency: Float? = nil) {
        guard let instrument = instruments.first(where: { $0.id == instrumentId }),
              !instrument.isMuted else { return }
        
        if let drumVoice = drumVoices[instrumentId] {
            drumVoice.trigger()
        } else if let synthVoice = synthVoices[instrumentId] {
            let freq = frequency ?? instrument.instrument.baseFrequency
            synthVoice.noteOn(frequency: freq)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 150_000_000)
                synthVoice.noteOff()
            }
        }
    }
    
    // MARK: - Step Control
    
    func toggleStep(_ step: Int, for instrumentId: Int) {
        guard let index = instruments.firstIndex(where: { $0.id == instrumentId }) else { return }
        instruments[index].toggleStep(step)
    }
    
    func setStepNote(_ step: Int, for instrumentId: Int, noteIndex: Int) {
        guard let index = instruments.firstIndex(where: { $0.id == instrumentId }) else { return }
        instruments[index].setStepNote(step, noteIndex: noteIndex)
    }
    
    func clearPattern(for instrumentId: Int) {
        guard let index = instruments.firstIndex(where: { $0.id == instrumentId }) else { return }
        instruments[index].clearPattern()
    }
    
    func clearAllPatterns() {
        for index in instruments.indices {
            instruments[index].clearPattern()
        }
    }
    
    func toggleMute(for instrumentId: Int) {
        guard let index = instruments.firstIndex(where: { $0.id == instrumentId }) else { return }
        instruments[index].isMuted.toggle()
    }
    
    // MARK: - Random Pattern
    
    func generateRandomPattern(for instrumentId: Int) {
        guard let index = instruments.firstIndex(where: { $0.id == instrumentId }) else { return }
        let instrument = instruments[index]
        
        instruments[index].clearPattern()
        
        let type = instrument.instrument
        
        switch type.category {
        case .drums:
            switch type {
            case .kick, .kick2:
                let patterns: [[Int]] = [[0, 4], [0, 3, 4, 7], [0, 2, 4, 6], [0, 4, 5]]
                let selected = patterns.randomElement() ?? [0, 4]
                for step in selected { instruments[index].steps[step].isActive = true }
            case .snare, .snare2, .rimshot:
                let patterns: [[Int]] = [[2, 6], [2, 5, 6], [2, 6, 7], [4]]
                let selected = patterns.randomElement() ?? [2, 6]
                for step in selected { instruments[index].steps[step].isActive = true }
            case .clap, .snap:
                let patterns: [[Int]] = [[2, 6], [3, 7], [2], [4, 6]]
                let selected = patterns.randomElement() ?? [2, 6]
                for step in selected { instruments[index].steps[step].isActive = true }
            case .tom:
                let patterns: [[Int]] = [[3, 7], [5, 6, 7], [1, 3, 5, 7]]
                let selected = patterns.randomElement() ?? [3, 7]
                for step in selected { instruments[index].steps[step].isActive = true }
            default:
                break
            }
            
        case .cymbals:
            switch type {
            case .hihatClosed, .hihatPedal:
                let patterns: [[Int]] = [Array(0..<8), [0, 2, 4, 6], [1, 3, 5, 7], [0, 1, 2, 3, 4, 5, 6, 7]]
                let selected = patterns.randomElement() ?? [0, 2, 4, 6]
                for step in selected { instruments[index].steps[step].isActive = true }
            case .hihatOpen:
                let patterns: [[Int]] = [[2, 6], [4], [0, 4], [2]]
                let selected = patterns.randomElement() ?? [2, 6]
                for step in selected { instruments[index].steps[step].isActive = true }
            case .crash, .china, .splash:
                let patterns: [[Int]] = [[0], [0, 4], []]
                let selected = patterns.randomElement() ?? [0]
                for step in selected { instruments[index].steps[step].isActive = true }
            case .ride:
                let patterns: [[Int]] = [[0, 2, 4, 6], [0, 4], Array(0..<8)]
                let selected = patterns.randomElement() ?? [0, 2, 4, 6]
                for step in selected { instruments[index].steps[step].isActive = true }
            default:
                break
            }
            
        case .percussion:
            let patterns: [[Int]] = [[2, 6], [1, 3, 5, 7], [0, 3, 4, 7], [2, 4, 6]]
            let selected = patterns.randomElement() ?? [2, 6]
            for step in selected { instruments[index].steps[step].isActive = true }
            
        case .bass, .leads, .pads, .arps:
            let rhythmPatterns: [[Int]] = [[0, 2, 4, 6], [0, 3, 4, 7], [0, 2, 5, 7], [0, 4], [0, 1, 4, 5], [0, 3, 5, 6]]
            let selected = rhythmPatterns.randomElement() ?? [0, 4]
            let scaleSize = instrument.instrument.scaleFrequencies.count
            
            for step in selected {
                instruments[index].steps[step].isActive = true
                let noteIndex: Int
                if Bool.random() {
                    noteIndex = [0, 2, 4].randomElement() ?? 0
                } else {
                    noteIndex = Int.random(in: 0..<min(scaleSize, 8))
                }
                instruments[index].steps[step].noteIndex = noteIndex
            }
            
        case .fx:
            let patterns: [[Int]] = [[0], [0, 4], [7], [0, 2, 4, 6]]
            let selected = patterns.randomElement() ?? [0]
            for step in selected { instruments[index].steps[step].isActive = true }
        }
    }
    
    func generateFullBeat() {
        // Only generate for a subset of instruments for a cleaner beat
        let essentialTypes: [InstrumentType] = [.kick, .snare, .hihatClosed, .clap, .bass, .lead]
        
        for instrument in instruments {
            if essentialTypes.contains(instrument.instrument) || Bool.random() && Bool.random() {
                generateRandomPattern(for: instrument.id)
            } else {
                clearPattern(for: instrument.id)
            }
        }
    }
    
    // MARK: - Transport
    
    func startPlayback() {
        isPlaying = true
        currentStep = 0
        
        let interval = 60.0 / bpm / 2.0
        
        beatTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                for instrument in self.instruments {
                    if instrument.steps[self.currentStep].isActive && !instrument.isMuted {
                        let freq = instrument.frequency(for: self.currentStep)
                        self.triggerInstrument(instrument.id, frequency: freq)
                    }
                }
                
                self.currentStep = (self.currentStep + 1) % self.stepCount
            }
        }
    }
    
    func stopPlayback() {
        isPlaying = false
        beatTimer?.invalidate()
        beatTimer = nil
        currentStep = 0
    }
    
    func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }
    
    func setBPM(_ newBPM: Double) {
        bpm = max(60, min(200, newBPM))
        if isPlaying {
            stopPlayback()
            startPlayback()
        }
    }
}
