//
//  PadModel.swift
//  DrumPadTry
//
//  Created by Marvin Krüger on 18.12.25.
//

import SwiftUI

// MARK: - Instrument Type

enum InstrumentType: String, CaseIterable {
    // Drums (Row 1)
    case kick = "Kick"
    case kick2 = "Kick 2"
    case snare = "Snare"
    case snare2 = "Snare 2"
    case rimshot = "Rim"
    case clap = "Clap"
    case snap = "Snap"
    case tom = "Tom"
    
    // Hi-Hats & Cymbals (Row 2)
    case hihatClosed = "HH Cls"
    case hihatOpen = "HH Opn"
    case hihatPedal = "HH Pdl"
    case crash = "Crash"
    case ride = "Ride"
    case china = "China"
    case splash = "Splash"
    case bell = "Bell"
    
    // Percussion (Row 3)
    case conga = "Conga"
    case bongo = "Bongo"
    case shaker = "Shaker"
    case tambourine = "Tamb"
    case cowbell = "Cowbll"
    case woodblock = "Wood"
    case triangle = "Tri"
    case agogo = "Agogo"
    
    // Bass (Row 4)
    case bass = "Bass"
    case bass2 = "Bass 2"
    case subBass = "Sub"
    case acidBass = "Acid"
    case pluckBass = "PlkBs"
    case wobble = "Wobble"
    case reese = "Reese"
    case fmBass = "FM Bs"
    
    // Leads (Row 5)
    case lead = "Lead"
    case lead2 = "Lead 2"
    case saw = "Saw"
    case square = "Square"
    case supersaw = "S.Saw"
    case hoover = "Hoover"
    case sync = "Sync"
    case formant = "Formnt"
    
    // Pads (Row 6)
    case pad = "Pad"
    case pad2 = "Pad 2"
    case strings = "String"
    case choir = "Choir"
    case ambient = "Ambnt"
    case sweep = "Sweep"
    case drone = "Drone"
    case texture = "Textur"
    
    // Arps & Plucks (Row 7)
    case arp = "Arp"
    case arp2 = "Arp 2"
    case pluck = "Pluck"
    case marimba = "Marimb"
    case vibes = "Vibes"
    case bells = "Bells"
    case keys = "Keys"
    case piano = "Piano"
    
    // FX & Misc (Row 8)
    case riser = "Riser"
    case downlift = "Down"
    case impact = "Impact"
    case noise = "Noise"
    case glitch = "Glitch"
    case stab = "Stab"
    case vox = "Vox"
    case fx = "FX"
    
    var icon: String {
        switch self {
        // Drums
        case .kick, .kick2: return "circle.fill"
        case .snare, .snare2: return "square.fill"
        case .rimshot: return "circlebadge"
        case .clap: return "hands.clap.fill"
        case .snap: return "hand.point.up.fill"
        case .tom: return "oval.fill"
        
        // Hi-Hats & Cymbals
        case .hihatClosed: return "xmark"
        case .hihatOpen: return "xmark.circle"
        case .hihatPedal: return "xmark.square"
        case .crash: return "star.fill"
        case .ride: return "star"
        case .china: return "staroflife.fill"
        case .splash: return "drop.fill"
        case .bell: return "bell.fill"
        
        // Percussion
        case .conga: return "oval.portrait.fill"
        case .bongo: return "circle.grid.2x1.fill"
        case .shaker: return "waveform"
        case .tambourine: return "circle.dashed"
        case .cowbell: return "bell"
        case .woodblock: return "rectangle.fill"
        case .triangle: return "triangle"
        case .agogo: return "tuningfork"
        
        // Bass
        case .bass, .bass2: return "waveform.path"
        case .subBass: return "waveform.path.ecg"
        case .acidBass: return "waveform.path.badge.minus"
        case .pluckBass: return "arrow.down.app.fill"
        case .wobble: return "waveform.path.badge.plus"
        case .reese: return "waveform.circle.fill"
        case .fmBass: return "function"
        
        // Leads
        case .lead, .lead2: return "bolt.fill"
        case .saw: return "triangle.fill"
        case .square: return "square.fill"
        case .supersaw: return "bolt.trianglebadge.exclamationmark.fill"
        case .hoover: return "wind"
        case .sync: return "arrow.triangle.2.circlepath"
        case .formant: return "mouth.fill"
        
        // Pads
        case .pad, .pad2: return "cloud.fill"
        case .strings: return "guitars.fill"
        case .choir: return "person.3.fill"
        case .ambient: return "sparkle"
        case .sweep: return "arrow.right"
        case .drone: return "infinity"
        case .texture: return "checkerboard.rectangle"
        
        // Arps & Plucks
        case .arp, .arp2: return "sparkles"
        case .pluck: return "hand.draw.fill"
        case .marimba: return "pianokeys"
        case .vibes: return "waveform.badge.magnifyingglass"
        case .bells: return "bell.badge.fill"
        case .keys: return "pianokeys.inverse"
        case .piano: return "pianokeys"
        
        // FX
        case .riser: return "arrow.up.right"
        case .downlift: return "arrow.down.right"
        case .impact: return "burst.fill"
        case .noise: return "aqi.medium"
        case .glitch: return "wand.and.rays"
        case .stab: return "bolt.horizontal.fill"
        case .vox: return "waveform.and.mic"
        case .fx: return "wand.and.stars"
        }
    }
    
    var category: InstrumentCategory {
        switch self {
        case .kick, .kick2, .snare, .snare2, .rimshot, .clap, .snap, .tom:
            return .drums
        case .hihatClosed, .hihatOpen, .hihatPedal, .crash, .ride, .china, .splash, .bell:
            return .cymbals
        case .conga, .bongo, .shaker, .tambourine, .cowbell, .woodblock, .triangle, .agogo:
            return .percussion
        case .bass, .bass2, .subBass, .acidBass, .pluckBass, .wobble, .reese, .fmBass:
            return .bass
        case .lead, .lead2, .saw, .square, .supersaw, .hoover, .sync, .formant:
            return .leads
        case .pad, .pad2, .strings, .choir, .ambient, .sweep, .drone, .texture:
            return .pads
        case .arp, .arp2, .pluck, .marimba, .vibes, .bells, .keys, .piano:
            return .arps
        case .riser, .downlift, .impact, .noise, .glitch, .stab, .vox, .fx:
            return .fx
        }
    }
    
    var baseFrequency: Float {
        switch self {
        // Drums
        case .kick: return 55
        case .kick2: return 50
        case .snare: return 200
        case .snare2: return 180
        case .rimshot: return 800
        case .clap: return 1200
        case .snap: return 2000
        case .tom: return 100
        
        // Cymbals
        case .hihatClosed: return 8000
        case .hihatOpen: return 7000
        case .hihatPedal: return 9000
        case .crash: return 6000
        case .ride: return 5000
        case .china: return 4500
        case .splash: return 7500
        case .bell: return 3000
        
        // Percussion
        case .conga: return 250
        case .bongo: return 400
        case .shaker: return 10000
        case .tambourine: return 8500
        case .cowbell: return 560
        case .woodblock: return 1800
        case .triangle: return 4000
        case .agogo: return 700
        
        // Bass
        case .bass: return 110
        case .bass2: return 82.41
        case .subBass: return 55
        case .acidBass: return 130.81
        case .pluckBass: return 98
        case .wobble: return 73.42
        case .reese: return 110
        case .fmBass: return 87.31
        
        // Leads
        case .lead: return 440
        case .lead2: return 523.25
        case .saw: return 329.63
        case .square: return 392
        case .supersaw: return 440
        case .hoover: return 293.66
        case .sync: return 349.23
        case .formant: return 261.63
        
        // Pads
        case .pad: return 220
        case .pad2: return 261.63
        case .strings: return 196
        case .choir: return 329.63
        case .ambient: return 174.61
        case .sweep: return 220
        case .drone: return 110
        case .texture: return 146.83
        
        // Arps
        case .arp: return 880
        case .arp2: return 659.26
        case .pluck: return 523.25
        case .marimba: return 587.33
        case .vibes: return 440
        case .bells: return 1046.50
        case .keys: return 392
        case .piano: return 261.63
        
        // FX
        case .riser: return 220
        case .downlift: return 880
        case .impact: return 80
        case .noise: return 5000
        case .glitch: return 1000
        case .stab: return 440
        case .vox: return 330
        case .fx: return 660
        }
    }
    
    var scaleFrequencies: [Float] {
        switch category {
        case .drums, .cymbals, .percussion:
            return [baseFrequency]
        case .bass:
            let base = baseFrequency
            return [base, base * 1.122, base * 1.26, base * 1.335, base * 1.498, base * 1.682, base * 1.888, base * 2.0]
        case .leads, .arps:
            let base = baseFrequency
            return [base, base * 1.122, base * 1.26, base * 1.414, base * 1.587, base * 1.782, base * 2.0, base * 2.245]
        case .pads:
            let base = baseFrequency
            return [base, base * 1.189, base * 1.335, base * 1.498, base * 1.682, base * 1.888, base * 2.0, base * 2.378]
        case .fx:
            return [baseFrequency]
        }
    }
    
    var isDrum: Bool {
        category == .drums || category == .cymbals || category == .percussion
    }
}

// MARK: - Instrument Category

enum InstrumentCategory: String {
    case drums = "Drums"
    case cymbals = "Cymbals"
    case percussion = "Percussion"
    case bass = "Bass"
    case leads = "Leads"
    case pads = "Pads"
    case arps = "Arps"
    case fx = "FX"
    
    var color: Color {
        switch self {
        case .drums: return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .cymbals: return Color(red: 1.0, green: 0.85, blue: 0.3)
        case .percussion: return Color(red: 1.0, green: 0.55, blue: 0.3)
        case .bass: return Color(red: 0.7, green: 0.3, blue: 1.0)
        case .leads: return Color(red: 0.3, green: 0.85, blue: 1.0)
        case .pads: return Color(red: 0.4, green: 0.5, blue: 1.0)
        case .arps: return Color(red: 0.4, green: 1.0, blue: 0.6)
        case .fx: return Color(red: 1.0, green: 0.4, blue: 0.7)
        }
    }
}

// MARK: - Instrument Theme

struct InstrumentTheme {
    let primary: Color
    let secondary: Color
    let glow: Color
    
    static func theme(for instrument: InstrumentType) -> InstrumentTheme {
        let categoryColor = instrument.category.color
        return InstrumentTheme(
            primary: categoryColor,
            secondary: categoryColor.opacity(0.7),
            glow: categoryColor.opacity(0.6)
        )
    }
}

// MARK: - Instrument Pad

struct InstrumentPad: Identifiable {
    let id: Int
    let instrument: InstrumentType
    var steps: [StepData] = Array(repeating: StepData(), count: 8)
    var isMuted: Bool = false
    var volume: Float = 0.8
    
    var theme: InstrumentTheme {
        InstrumentTheme.theme(for: instrument)
    }
    
    var hasActiveSteps: Bool {
        steps.contains { $0.isActive }
    }
    
    mutating func toggleStep(_ index: Int) {
        guard index >= 0 && index < steps.count else { return }
        steps[index].isActive.toggle()
    }
    
    mutating func setStepNote(_ index: Int, noteIndex: Int) {
        guard index >= 0 && index < steps.count else { return }
        steps[index].noteIndex = noteIndex
    }
    
    mutating func clearPattern() {
        steps = Array(repeating: StepData(), count: 8)
    }
    
    func frequency(for stepIndex: Int) -> Float {
        let noteIndex = steps[stepIndex].noteIndex
        let frequencies = instrument.scaleFrequencies
        return frequencies[min(noteIndex, frequencies.count - 1)]
    }
    
    static func defaultInstruments() -> [InstrumentPad] {
        return InstrumentType.allCases.enumerated().map { index, type in
            InstrumentPad(id: index, instrument: type)
        }
    }
}

// MARK: - Step Data

struct StepData {
    var isActive: Bool = false
    var noteIndex: Int = 0
    var velocity: Float = 1.0
}
