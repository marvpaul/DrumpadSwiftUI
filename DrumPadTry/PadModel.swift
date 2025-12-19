//
//  PadModel.swift
//  DrumPadTry
//
//  Created by Marvin Krüger on 18.12.25.
//

import SwiftUI

// MARK: - Pad Color Theme

enum PadColorTheme: CaseIterable {
    case red, orange, yellow, green, cyan, blue, purple, pink, white
    
    var primary: Color {
        switch self {
        case .red: return Color(red: 1.0, green: 0.2, blue: 0.2)
        case .orange: return Color(red: 1.0, green: 0.5, blue: 0.1)
        case .yellow: return Color(red: 1.0, green: 0.9, blue: 0.2)
        case .green: return Color(red: 0.2, green: 0.9, blue: 0.4)
        case .cyan: return Color(red: 0.2, green: 0.9, blue: 0.9)
        case .blue: return Color(red: 0.2, green: 0.4, blue: 1.0)
        case .purple: return Color(red: 0.6, green: 0.2, blue: 1.0)
        case .pink: return Color(red: 1.0, green: 0.3, blue: 0.6)
        case .white: return Color(red: 0.95, green: 0.95, blue: 0.95)
        }
    }
    
    var glow: Color {
        primary.opacity(0.6)
    }
    
    var dim: Color {
        primary.opacity(0.3)
    }
}

// MARK: - Musical Note

enum MusicalNote: String, CaseIterable {
    case C, Cs, D, Ds, E, F, Fs, G, Gs, A, As, B
    
    var displayName: String {
        switch self {
        case .Cs: return "C#"
        case .Ds: return "D#"
        case .Fs: return "F#"
        case .Gs: return "G#"
        case .As: return "A#"
        default: return rawValue
        }
    }
    
    func frequency(octave: Int) -> Float {
        let semitones: [MusicalNote: Int] = [
            .C: 0, .Cs: 1, .D: 2, .Ds: 3, .E: 4, .F: 5,
            .Fs: 6, .G: 7, .Gs: 8, .A: 9, .As: 10, .B: 11
        ]
        
        let semitonesFromA4 = semitones[self]! - 9 + (octave - 4) * 12
        return 440.0 * pow(2.0, Float(semitonesFromA4) / 12.0)
    }
}

// MARK: - Pad Configuration

struct PadConfiguration: Identifiable {
    let id: Int
    var synthType: SynthType
    var triggerMode: TriggerMode
    var colorTheme: PadColorTheme
    var note: MusicalNote
    var octave: Int
    var label: String
    
    var frequency: Float {
        note.frequency(octave: octave)
    }
    
    static func defaultGrid() -> [PadConfiguration] {
        var pads: [PadConfiguration] = []
        
        // Row 1: Drums (Red/Orange)
        pads.append(PadConfiguration(id: 0, synthType: .kick, triggerMode: .oneShot, colorTheme: .red, note: .C, octave: 2, label: "KICK"))
        pads.append(PadConfiguration(id: 1, synthType: .kick, triggerMode: .oneShot, colorTheme: .red, note: .C, octave: 2, label: "KICK 2"))
        pads.append(PadConfiguration(id: 2, synthType: .snare, triggerMode: .oneShot, colorTheme: .orange, note: .D, octave: 2, label: "SNARE"))
        pads.append(PadConfiguration(id: 3, synthType: .snare, triggerMode: .oneShot, colorTheme: .orange, note: .D, octave: 2, label: "SNARE 2"))
        pads.append(PadConfiguration(id: 4, synthType: .hihat, triggerMode: .oneShot, colorTheme: .yellow, note: .E, octave: 2, label: "HH CL"))
        pads.append(PadConfiguration(id: 5, synthType: .hihat, triggerMode: .oneShot, colorTheme: .yellow, note: .F, octave: 2, label: "HH OP"))
        pads.append(PadConfiguration(id: 6, synthType: .hihat, triggerMode: .oneShot, colorTheme: .yellow, note: .G, octave: 2, label: "HH"))
        pads.append(PadConfiguration(id: 7, synthType: .hihat, triggerMode: .oneShot, colorTheme: .yellow, note: .A, octave: 2, label: "PERC"))
        
        // Row 2: Bass notes (Purple)
        let bassNotes: [MusicalNote] = [.C, .D, .E, .F, .G, .A, .B, .C]
        for i in 0..<8 {
            let octave = i == 7 ? 3 : 2
            pads.append(PadConfiguration(id: 8 + i, synthType: .bass, triggerMode: .hold, colorTheme: .purple, note: bassNotes[i], octave: octave, label: "\(bassNotes[i].displayName)\(octave)"))
        }
        
        // Row 3: Lead notes (Cyan)
        let leadNotes: [MusicalNote] = [.C, .D, .E, .F, .G, .A, .B, .C]
        for i in 0..<8 {
            let octave = i == 7 ? 5 : 4
            pads.append(PadConfiguration(id: 16 + i, synthType: .lead, triggerMode: .hold, colorTheme: .cyan, note: leadNotes[i], octave: octave, label: "\(leadNotes[i].displayName)\(octave)"))
        }
        
        // Row 4: Pad sounds (Blue)
        let padNotes: [MusicalNote] = [.C, .E, .G, .B, .C, .E, .G, .B]
        for i in 0..<8 {
            let octave = i < 4 ? 3 : 4
            pads.append(PadConfiguration(id: 24 + i, synthType: .pad, triggerMode: .toggle, colorTheme: .blue, note: padNotes[i], octave: octave, label: "PAD"))
        }
        
        // Row 5: Pluck sounds (Green)
        let pluckNotes: [MusicalNote] = [.C, .D, .E, .G, .A, .C, .D, .E]
        for i in 0..<8 {
            let octave = i < 5 ? 4 : 5
            pads.append(PadConfiguration(id: 32 + i, synthType: .pluck, triggerMode: .oneShot, colorTheme: .green, note: pluckNotes[i], octave: octave, label: "PLCK"))
        }
        
        // Row 6: More plucks (Green)
        let pluck2Notes: [MusicalNote] = [.G, .A, .B, .C, .D, .E, .Fs, .G]
        for i in 0..<8 {
            let octave = i < 3 ? 4 : 5
            pads.append(PadConfiguration(id: 40 + i, synthType: .pluck, triggerMode: .oneShot, colorTheme: .green, note: pluck2Notes[i], octave: octave, label: "PLCK"))
        }
        
        // Row 7: FX sounds (Pink)
        let fxNotes: [MusicalNote] = [.C, .Ds, .F, .G, .As, .C, .Ds, .F]
        for i in 0..<8 {
            let octave = i < 5 ? 3 : 4
            pads.append(PadConfiguration(id: 48 + i, synthType: .fx, triggerMode: .toggle, colorTheme: .pink, note: fxNotes[i], octave: octave, label: "FX"))
        }
        
        // Row 8: More FX (Pink/White)
        for i in 0..<8 {
            let color: PadColorTheme = i < 4 ? .pink : .white
            pads.append(PadConfiguration(id: 56 + i, synthType: .fx, triggerMode: .toggle, colorTheme: color, note: fxNotes[i], octave: 4, label: "FX"))
        }
        
        return pads
    }
}

