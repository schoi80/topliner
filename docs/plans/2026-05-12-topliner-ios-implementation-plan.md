# Topliner iOS Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Build an iOS music production app that lets a user record or draw a lead melody, generates a style-matched chord progression on-device, plays it back with a simple wavetable synth, and exports/sends MIDI to external devices or DAWs over Bluetooth MIDI and WiFi/RTP-MIDI.

**Architecture:** The app is a SwiftUI-first, offline-capable composition tool with three core pipelines: lead-voice capture/editing, on-device chord-generation inference, and audio/MIDI playback/export. The same canonical `LeadVoiceBuffer` feeds both the piano-roll editor and the chord-generation engine, so mic capture and manual MIDI entry stay interchangeable.

**Tech Stack:** Swift 5.9+, SwiftUI, Observation, AVFoundation/AVAudioEngine, AudioKit/SoundpipeAudioKit, Core MIDI, optional Ableton Link later, LiteRT-LM via LiteRTLM-Swift, XCTest, XCUITest.

---

## 1. Product Summary

### Working product name

Topliner

### One-sentence pitch

Topliner is a mobile-first harmonic sketchpad that turns hummed or manually-entered lead melodies into genre-aware chord progressions and sends the result directly to a DAW or MIDI hardware.

### Primary user

Music producers, songwriters, keyboardists, and beatmakers who have a lead idea but want fast harmonic options in styles such as neo-soul, jazz, gospel, R&B, city pop, bossa nova, blues, funk, synthwave, and cinematic music.

### Core value proposition

The app shortens the path from melody idea to usable harmony:

1. Capture a melody by humming into the phone or entering notes in a minimal piano roll.
2. Choose a harmonic style.
3. Generate matching chords locally on the device.
4. Hear the result immediately through a built-in synth.
5. Export or stream the MIDI to a DAW/hardware over Bluetooth or WiFi.

---

## 2. MVP Scope

### MVP must include

1. iOS app shell with SwiftUI navigation.
2. Project/session state for a 4-bar lead idea.
3. Minimal piano-roll editor for monophonic lead-voice input.
4. Microphone recording path that captures audio and optionally displays a ghost pitch trace.
5. Deterministic pitch-to-MIDI draft transcription using AudioKit/SoundpipeAudioKit.
6. LiteRT-LM integration seam with a mock provider first, then real LiteRTLM-Swift provider.
7. Chord-generation prompt and JSON output contract.
8. Style presets with genre-specific harmonic constraints.
9. Chord validator/parser to convert generated chord symbols to MIDI notes.
10. Local wavetable/sampler playback for lead and generated chords.
11. Core MIDI virtual output.
12. Bluetooth MIDI pairing UI.
13. RTP-MIDI/network MIDI enablement.
14. MIDI file export.
15. Basic save/load of local projects.

### MVP should not include yet

1. Full DAW timeline.
2. Multi-track arrangement.
3. Audio-to-chord direct inference without a deterministic fallback.
4. Model fine-tuning pipeline.
5. Account system or cloud sync.
6. Paid subscriptions.
7. Spotify/Rekordbox library integration.
8. Advanced sound design.

### Important architecture decision

The transcript explored direct native audio input into a multimodal edge LLM. Treat that as an experiment, not as the only path. The reliable MVP path should be:

Mic audio -> deterministic pitch tracking -> editable `LeadVoiceBuffer` -> LiteRT-LM symbolic chord reasoning -> chord validation -> playback/MIDI.

A direct audio-to-chords LiteRT path can be added behind the same `ChordGenerationProvider` protocol once model support, memory use, and quality are proven on device.

---

## 3. User Flows

### Flow A: Hum-to-harmony

1. User opens a new project.
2. User sets tempo, key/scale if known, and bar length.
3. User taps Record.
4. App records mic audio.
5. App shows a live ghost pitch trace on the piano roll.
6. User taps Stop.
7. App converts the recording to draft MIDI notes.
8. App quantizes and displays notes in the piano roll.
9. User optionally edits notes.
10. User chooses a style, e.g. Neo-Soul.
11. User taps Generate Chords.
12. App runs chord-generation inference.
13. App validates generated chords and maps them to voicings.
14. App plays lead plus chords locally.
15. App sends MIDI to connected DAW/hardware if enabled.
16. User exports MIDI if desired.

### Flow B: Piano-roll melody to harmony

1. User opens a new project.
2. User taps notes into the piano roll.
3. User drags note edges to adjust durations.
4. User presses Play to audition the lead.
5. User chooses style.
6. User generates chords.
7. User auditions, regenerates, or locks preferred chords.
8. User exports or streams MIDI.

### Flow C: DAW integration

1. User opens MIDI Settings.
2. User enables Virtual MIDI Output.
3. User optionally opens Bluetooth MIDI pairing.
4. User optionally enables Network MIDI/RTP-MIDI.
5. User chooses whether playback sends lead, chords, or both.
6. DAW records incoming MIDI from the iPhone.

---

## 4. Harmonic Style System

Represent each style as data first, not hard-coded conditionals. The LLM prompt uses the style profile, and the validator/voicer uses it as constraints.

### Style profile fields

```swift
struct HarmonicStyleProfile: Codable, Identifiable, Equatable {
    let id: String
    let displayName: String
    let summary: String
    let preferredChordQualities: [ChordQuality]
    let allowedExtensions: [ChordExtension]
    let commonProgressions: [RomanNumeralProgression]
    let substitutionRules: [SubstitutionRule]
    let voicingGuidance: VoicingGuidance
    let rhythmGuidance: RhythmGuidance
    let avoidNotes: [ScaleDegree]
    let promptInstructions: String
}
```

### Initial styles

#### Neo-Soul

Characteristics:

- Extended chords: maj9, min9, min11, 13sus, add9, 6/9.
- Smooth voice leading and close movement between chord tones.
- Frequent borrowed chords and non-obvious resolutions.
- Quartal colors and upper-structure voicings.
- Bass movement can be chromatic or stepwise.

Progression seeds:

- i9 -> iv9 -> bVII13 -> bIIImaj9.
- Imaj9 -> iii7 -> vi9 -> ii11 -> V13sus.
- IVmaj9 -> iii7 -> vi9 -> bVII13.

#### Jazz

Characteristics:

- ii-V-I and turnarounds.
- Altered dominants.
- Secondary dominants.
- Tritone substitution.
- Extensions up to 13ths.

Progression seeds:

- ii7 -> V7alt -> Imaj7.
- Imaj7 -> vi7 -> ii7 -> V7.
- iii7 -> VI7 -> ii7 -> V7 -> Imaj7.

#### Gospel/R&B

Characteristics:

- Kinetic passing chords.
- Secondary dominants.
- Diminished approach chords.
- Walk-ups and walk-downs.
- Rich inversions/slash chords.

Progression seeds:

- I -> V/ii -> ii -> V -> I.
- I -> I/iii -> IV -> #ivdim7 -> V.
- I -> biiiDim7 -> ii7 -> V13 -> I.

#### City Pop/J-Pop

Characteristics:

- Royal Road progression.
- Sentimental major/minor ambiguity.
- Slash chords for bass movement.
- Jazz-pop sevenths and ninths.

Progression seeds:

- IVmaj7 -> V7 -> iii7 -> vi7.
- ii7 -> V7 -> Imaj7 -> VI7.
- Imaj7 -> V/vi -> vi7 -> V7/IV -> IVmaj7.

#### Bossa Nova

Characteristics:

- Jazz harmony with soft rhythmic placement.
- Major 7ths, minor 7ths, half-diminished chords.
- Subtle modulations.
- Static melody over moving chromatic harmony.

Progression seeds:

- ii7 -> V7 -> Imaj7 -> VI7.
- i6 -> iiø7 -> V7b9 -> i6.
- Imaj7 -> #idim7 -> ii7 -> V7.

#### Blues

Characteristics:

- Dominant I, IV, and V.
- 12-bar structure.
- Minor melodic color over dominant harmony.
- Turnarounds.

Progression seeds:

- I7 -> IV7 -> I7 -> I7 -> IV7 -> IV7 -> I7 -> I7 -> V7 -> IV7 -> I7 -> V7.
- I7 -> IV7 -> I7 -> V7.

#### Funk

Characteristics:

- Static dominant or minor vamp.
- Rhythmic stabs.
- 7#9 and 9sus colors.
- Less harmonic movement, more groove emphasis.

Progression seeds:

- i7 -> i7 -> bVII9 -> i7.
- I7#9 vamp.
- i9 -> IV9 vamp.

#### Synthwave/80s Pop

Characteristics:

- Modal mixture.
- Dramatic minor progressions.
- bVI-bVII-i lift.
- Pedal tones.

Progression seeds:

- i -> bVI -> bIII -> bVII.
- bVI -> bVII -> i.
- i -> bVII -> bVI -> bVII.

#### Cinematic/Epic

Characteristics:

- Modal harmony.
- Open voicings.
- Pedal points.
- Chromatic mediants.
- Suspended resolution.

Progression seeds:

- i -> bVI -> bIII -> bVII.
- I -> bVII -> IV -> I.
- i -> bIII -> bVI -> iv.

---

## 5. Proposed Repository Structure

Create an Xcode project at the repo root. Suggested paths:

```text
Topliner.xcodeproj
Topliner/
  App/
    ToplinerApp.swift
    AppEnvironment.swift
  Models/
    ProjectDocument.swift
    LeadVoiceBuffer.swift
    MIDINoteEvent.swift
    ChordProgression.swift
    HarmonicStyleProfile.swift
  Features/
    ProjectBrowser/
      ProjectBrowserView.swift
      ProjectBrowserViewModel.swift
    Composer/
      ComposerView.swift
      ComposerViewModel.swift
    PianoRoll/
      PianoRollView.swift
      PianoRollGridView.swift
      PianoRollCanvasView.swift
      PianoRollInteractionLayer.swift
      PlayheadView.swift
      PianoRollGeometry.swift
    Capture/
      AudioCaptureView.swift
      AudioCaptureViewModel.swift
      PitchTraceView.swift
    ChordGeneration/
      ChordGenerationView.swift
      ChordGenerationViewModel.swift
      StylePickerView.swift
    MIDISettings/
      MIDISettingsView.swift
      BluetoothMIDIPairingView.swift
  Services/
    Audio/
      AudioEngineService.swift
      WavetableSynthService.swift
      PitchTrackingService.swift
      SequencerService.swift
    MIDI/
      MIDIOutputService.swift
      BluetoothMIDIService.swift
      NetworkMIDIService.swift
      MIDIFileExporter.swift
    Inference/
      ChordGenerationProvider.swift
      MockChordGenerationProvider.swift
      LiteRTChordGenerationProvider.swift
      PromptBuilder.swift
      ChordGenerationResponseParser.swift
    Theory/
      ChordSymbolParser.swift
      ChordVoicer.swift
      ChordValidator.swift
      Quantizer.swift
      KeyDetector.swift
      StyleLibrary.swift
  Resources/
    Styles/harmonic_styles.json
    Wavetables/default_wavetable.wav
    Models/.gitkeep
  Utilities/
    Debouncer.swift
    Logger.swift
ToplinerTests/
  Models/
  Services/
  Theory/
  Inference/
ToplinerUITests/
  PianoRollUITests.swift
docs/
  product/
    product-requirements.md
    technical-architecture.md
  plans/
    2026-05-12-topliner-ios-implementation-plan.md
```

---

## 6. Core Data Models

### `MIDINoteEvent`

```swift
import Foundation

struct MIDINoteEvent: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var pitch: Int
    var startBeat: Double
    var durationBeats: Double
    var velocity: Int

    var endBeat: Double { startBeat + durationBeats }
}
```

Validation rules:

- `pitch` must be 0...127.
- `startBeat` must be >= 0.
- `durationBeats` must be > 0.
- `velocity` must be 1...127.

### `LeadVoiceBuffer`

```swift
import Foundation

struct LeadVoiceBuffer: Codable, Equatable {
    var notes: [MIDINoteEvent]
    var source: LeadVoiceSource
    var quantizeGrid: Double

    var sortedNotes: [MIDINoteEvent] {
        notes.sorted { lhs, rhs in
            if lhs.startBeat == rhs.startBeat { return lhs.pitch < rhs.pitch }
            return lhs.startBeat < rhs.startBeat
        }
    }
}

enum LeadVoiceSource: String, Codable, Equatable {
    case pianoRoll
    case microphone
    case importedMIDI
}
```

### `ChordEvent`

```swift
import Foundation

struct ChordEvent: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var symbol: String
    var rootMidiNote: Int
    var midiNotes: [Int]
    var startBeat: Double
    var durationBeats: Double
    var romanNumeral: String?
    var confidence: Double?
}
```

### `ChordProgression`

```swift
import Foundation

struct ChordProgression: Codable, Equatable {
    var styleID: String
    var key: String?
    var chords: [ChordEvent]
    var explanation: String?
}
```

### `ProjectDocument`

```swift
import Foundation

struct ProjectDocument: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var bpm: Double
    var beatsPerBar: Int
    var totalBars: Int
    var key: String?
    var scale: String?
    var leadVoice: LeadVoiceBuffer
    var chordProgression: ChordProgression?
}
```

---

## 7. Inference Contract

### Provider abstraction

```swift
protocol ChordGenerationProvider {
    func generateChords(request: ChordGenerationRequest) async throws -> ChordGenerationResult
}
```

### Request

```swift
struct ChordGenerationRequest: Codable, Equatable {
    var leadVoice: LeadVoiceBuffer
    var bpm: Double
    var beatsPerBar: Int
    var totalBars: Int
    var key: String?
    var scale: String?
    var style: HarmonicStyleProfile
    var chordChangeGrid: Double
    var outputComplexity: OutputComplexity
}

enum OutputComplexity: String, Codable, Equatable {
    case simple
    case balanced
    case advanced
}
```

### Required LLM JSON output

```json
{
  "key": "C minor",
  "style_id": "neo_soul",
  "chords": [
    {
      "symbol": "Cm9",
      "roman_numeral": "i9",
      "start_beat": 0.0,
      "duration_beats": 2.0,
      "midi_notes": [48, 55, 58, 62, 67]
    },
    {
      "symbol": "Fm9",
      "roman_numeral": "iv9",
      "start_beat": 2.0,
      "duration_beats": 2.0,
      "midi_notes": [53, 60, 63, 67, 72]
    }
  ],
  "explanation": "Uses minor 9th colors and stepwise upper-voice movement."
}
```

### Prompt rules

The prompt builder must instruct the model to:

1. Return JSON only.
2. Use the requested style profile.
3. Preserve melody notes on strong beats as chord tones or tasteful extensions where possible.
4. Prefer smooth voice leading.
5. Avoid impossible pitch ranges.
6. Keep chord starts/durations aligned to the requested grid.
7. Include MIDI notes for every chord.
8. Use a fixed output schema.

### Validation rules after inference

1. JSON must parse.
2. Chord events must cover the requested region or explicitly leave intentional gaps.
3. `start_beat` and `duration_beats` must align to grid.
4. MIDI notes must be 0...127.
5. Chord symbols must parse.
6. Style constraints should be checked; violations are either corrected or surfaced.
7. Voice-leading jumps should be minimized by `ChordVoicer` even if raw model output is rough.

---

## 8. Implementation Tasks

### Task 1: Create the Xcode project skeleton

**Objective:** Add a buildable iOS SwiftUI app project to the empty repository.

**Files:**

- Create: `Topliner.xcodeproj`
- Create: `Topliner/App/ToplinerApp.swift`
- Create: `Topliner/App/AppEnvironment.swift`
- Create: `ToplinerTests/ToplinerTests.swift`
- Create: `ToplinerUITests/ToplinerUITests.swift`

**Step 1: Create project**

Use Xcode or `xcodegen` if the team chooses to add it. If using Xcode manually:

1. File -> New -> Project.
2. Platform: iOS.
3. Template: App.
4. Product Name: `Topliner`.
5. Interface: SwiftUI.
6. Language: Swift.
7. Include Tests: yes.
8. Save at repo root.

**Step 2: Verify build**

Run:

```bash
xcodebuild -scheme Topliner -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: build succeeds.

**Step 3: Commit**

```bash
git add Topliner.xcodeproj Topliner ToplinerTests ToplinerUITests
git commit -m "chore: create iOS app skeleton"
```

---

### Task 2: Add core MIDI note model tests

**Objective:** Define and test the basic note event model.

**Files:**

- Create: `Topliner/Models/MIDINoteEvent.swift`
- Create: `ToplinerTests/Models/MIDINoteEventTests.swift`

**Step 1: Write failing tests**

```swift
import XCTest
@testable import Topliner

final class MIDINoteEventTests: XCTestCase {
    func testEndBeatAddsStartAndDuration() {
        let note = MIDINoteEvent(pitch: 60, startBeat: 1.5, durationBeats: 0.5, velocity: 100)
        XCTAssertEqual(note.endBeat, 2.0)
    }

    func testCodableRoundTrip() throws {
        let note = MIDINoteEvent(pitch: 64, startBeat: 0, durationBeats: 1, velocity: 90)
        let data = try JSONEncoder().encode(note)
        let decoded = try JSONDecoder().decode(MIDINoteEvent.self, from: data)
        XCTAssertEqual(decoded.pitch, 64)
        XCTAssertEqual(decoded.startBeat, 0)
        XCTAssertEqual(decoded.durationBeats, 1)
        XCTAssertEqual(decoded.velocity, 90)
    }
}
```

**Step 2: Run tests to verify failure**

```bash
xcodebuild test -scheme Topliner -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:ToplinerTests/MIDINoteEventTests
```

Expected: fails because `MIDINoteEvent` does not exist.

**Step 3: Implement model**

```swift
import Foundation

struct MIDINoteEvent: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var pitch: Int
    var startBeat: Double
    var durationBeats: Double
    var velocity: Int

    var endBeat: Double { startBeat + durationBeats }
}
```

**Step 4: Run tests to verify pass**

Expected: all `MIDINoteEventTests` pass.

**Step 5: Commit**

```bash
git add Topliner/Models/MIDINoteEvent.swift ToplinerTests/Models/MIDINoteEventTests.swift
git commit -m "feat: add MIDI note event model"
```

---

### Task 3: Add lead voice buffer model

**Objective:** Create the canonical melody container shared by microphone capture and piano-roll editing.

**Files:**

- Create: `Topliner/Models/LeadVoiceBuffer.swift`
- Create: `ToplinerTests/Models/LeadVoiceBufferTests.swift`

**Step 1: Write failing tests**

```swift
import XCTest
@testable import Topliner

final class LeadVoiceBufferTests: XCTestCase {
    func testSortedNotesOrdersByStartBeatThenPitch() {
        let high = MIDINoteEvent(pitch: 72, startBeat: 1, durationBeats: 1, velocity: 100)
        let low = MIDINoteEvent(pitch: 60, startBeat: 1, durationBeats: 1, velocity: 100)
        let first = MIDINoteEvent(pitch: 64, startBeat: 0, durationBeats: 1, velocity: 100)
        let buffer = LeadVoiceBuffer(notes: [high, first, low], source: .pianoRoll, quantizeGrid: 0.25)

        XCTAssertEqual(buffer.sortedNotes.map(\.pitch), [64, 60, 72])
    }
}
```

**Step 2: Implement model**

```swift
import Foundation

struct LeadVoiceBuffer: Codable, Equatable {
    var notes: [MIDINoteEvent]
    var source: LeadVoiceSource
    var quantizeGrid: Double

    var sortedNotes: [MIDINoteEvent] {
        notes.sorted { lhs, rhs in
            if lhs.startBeat == rhs.startBeat { return lhs.pitch < rhs.pitch }
            return lhs.startBeat < rhs.startBeat
        }
    }
}

enum LeadVoiceSource: String, Codable, Equatable {
    case pianoRoll
    case microphone
    case importedMIDI
}
```

**Step 3: Run tests**

Expected: pass.

**Step 4: Commit**

```bash
git add Topliner/Models/LeadVoiceBuffer.swift ToplinerTests/Models/LeadVoiceBufferTests.swift
git commit -m "feat: add lead voice buffer"
```

---

### Task 4: Add chord models

**Objective:** Represent generated chord events and progressions.

**Files:**

- Create: `Topliner/Models/ChordProgression.swift`
- Create: `ToplinerTests/Models/ChordProgressionTests.swift`

**Step 1: Write tests**

Test that chord progressions encode/decode and preserve symbols, beats, and MIDI notes.

**Step 2: Implement**

```swift
import Foundation

struct ChordEvent: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var symbol: String
    var rootMidiNote: Int
    var midiNotes: [Int]
    var startBeat: Double
    var durationBeats: Double
    var romanNumeral: String?
    var confidence: Double?
}

struct ChordProgression: Codable, Equatable {
    var styleID: String
    var key: String?
    var chords: [ChordEvent]
    var explanation: String?
}
```

**Step 3: Run tests and commit**

```bash
xcodebuild test -scheme Topliner -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:ToplinerTests/ChordProgressionTests
git add Topliner/Models/ChordProgression.swift ToplinerTests/Models/ChordProgressionTests.swift
git commit -m "feat: add chord progression models"
```

---

### Task 5: Add project document model

**Objective:** Store a complete sketch session.

**Files:**

- Create: `Topliner/Models/ProjectDocument.swift`
- Create: `ToplinerTests/Models/ProjectDocumentTests.swift`

**Implementation:**

Use the `ProjectDocument` structure in section 6.

**Tests:**

- Default 4-bar project can be created.
- Codable round trip preserves BPM, lead notes, and chord progression.

**Commit:**

```bash
git commit -m "feat: add project document model"
```

---

### Task 6: Implement quantizer

**Objective:** Quantize arbitrary beats and note events to a rhythmic grid.

**Files:**

- Create: `Topliner/Services/Theory/Quantizer.swift`
- Create: `ToplinerTests/Services/Theory/QuantizerTests.swift`

**Step 1: Tests**

```swift
import XCTest
@testable import Topliner

final class QuantizerTests: XCTestCase {
    func testQuantizesBeatToNearestSixteenth() {
        XCTAssertEqual(Quantizer.quantizeBeat(0.24, grid: 0.25), 0.25, accuracy: 0.0001)
        XCTAssertEqual(Quantizer.quantizeBeat(0.12, grid: 0.25), 0.0, accuracy: 0.0001)
    }

    func testQuantizesNoteStartAndDuration() {
        let note = MIDINoteEvent(pitch: 60, startBeat: 0.26, durationBeats: 0.49, velocity: 100)
        let result = Quantizer.quantize(note: note, grid: 0.25, minimumDuration: 0.25)
        XCTAssertEqual(result.startBeat, 0.25, accuracy: 0.0001)
        XCTAssertEqual(result.durationBeats, 0.5, accuracy: 0.0001)
    }
}
```

**Step 2: Implementation**

```swift
enum Quantizer {
    static func quantizeBeat(_ beat: Double, grid: Double) -> Double {
        guard grid > 0 else { return beat }
        return (beat / grid).rounded() * grid
    }

    static func quantize(note: MIDINoteEvent, grid: Double, minimumDuration: Double) -> MIDINoteEvent {
        var copy = note
        copy.startBeat = quantizeBeat(note.startBeat, grid: grid)
        copy.durationBeats = max(minimumDuration, quantizeBeat(note.durationBeats, grid: grid))
        return copy
    }
}
```

**Step 3: Verify and commit**

```bash
git commit -m "feat: add beat quantizer"
```

---

### Task 7: Implement piano-roll geometry mapper

**Objective:** Convert between screen coordinates and musical coordinates.

**Files:**

- Create: `Topliner/Features/PianoRoll/PianoRollGeometry.swift`
- Create: `ToplinerTests/Features/PianoRoll/PianoRollGeometryTests.swift`

**Required API:**

```swift
struct PianoRollGeometry {
    var size: CGSize
    var pitchRange: ClosedRange<Int>
    var totalBeats: Double
    var quantizeGrid: Double

    func rect(for note: MIDINoteEvent) -> CGRect
    func beat(atX x: CGFloat) -> Double
    func pitch(atY y: CGFloat) -> Int
    func noteStart(at point: CGPoint) -> (pitch: Int, beat: Double)
}
```

**Tests:**

- Left edge maps to beat 0.
- Right edge maps to total beats.
- Top row maps to highest pitch.
- Bottom row maps to lowest pitch.
- Note rect width equals duration/totalBeats times view width.

**Commit:**

```bash
git commit -m "feat: add piano roll geometry mapper"
```

---

### Task 8: Build static piano-roll grid

**Objective:** Render the timeline and pitch lanes.

**Files:**

- Create: `Topliner/Features/PianoRoll/PianoRollGridView.swift`
- Modify: `Topliner/Features/Composer/ComposerView.swift`

**Implementation notes:**

- Use `Canvas` or `Shape` for grid lines.
- Vertical lines: every beat, stronger line per bar.
- Horizontal lines: every pitch lane.
- Dark background.
- Keep text minimal for MVP.

**Manual verification:**

- Launch app.
- Confirm 4 bars show at 4/4.
- Confirm grid is visible and not visually noisy.

**Commit:**

```bash
git commit -m "feat: render piano roll grid"
```

---

### Task 9: Render note blocks on canvas

**Objective:** Display `LeadVoiceBuffer.notes` in the piano roll.

**Files:**

- Create: `Topliner/Features/PianoRoll/PianoRollCanvasView.swift`
- Modify: `Topliner/Features/PianoRoll/PianoRollView.swift`

**Implementation notes:**

- Draw notes as rounded rectangles.
- Selected notes use a brighter color/stroke.
- Use geometry mapper from Task 7.

**Tests:**

- Unit-test geometry, not visual drawing.
- Add SwiftUI preview with sample notes.

**Commit:**

```bash
git commit -m "feat: render piano roll notes"
```

---

### Task 10: Add tap-to-place notes

**Objective:** Let users add lead notes by tapping the grid.

**Files:**

- Create: `Topliner/Features/PianoRoll/PianoRollInteractionLayer.swift`
- Modify: `Topliner/Features/PianoRoll/PianoRollView.swift`
- Modify: `Topliner/Features/Composer/ComposerViewModel.swift`

**Behavior:**

- Tap adds one note at quantized beat/pitch.
- Default duration: 1 beat.
- Default velocity: 100.
- If tapping an existing note, select it instead of adding.

**Tests:**

- View-model test: adding note appends expected `MIDINoteEvent`.
- View-model test: added note is quantized.

**Commit:**

```bash
git commit -m "feat: add tap note entry"
```

---

### Task 11: Add drag-to-move notes

**Objective:** Let users move notes in time and pitch.

**Files:**

- Modify: `Topliner/Features/PianoRoll/PianoRollInteractionLayer.swift`
- Modify: `Topliner/Features/Composer/ComposerViewModel.swift`
- Add tests: `ToplinerTests/Features/Composer/ComposerViewModelTests.swift`

**Behavior:**

- Drag selected note to new pitch/beat.
- Clamp pitch to visible range.
- Clamp start beat to >= 0.
- Quantize final position.

**Commit:**

```bash
git commit -m "feat: move piano roll notes"
```

---

### Task 12: Add resize note duration

**Objective:** Let users drag a note edge to change duration.

**Files:**

- Modify: `PianoRollInteractionLayer.swift`
- Modify: `ComposerViewModel.swift`

**Behavior:**

- Drag right edge to change duration.
- Minimum duration: one quantize grid unit.
- Duration snaps to grid.

**Commit:**

```bash
git commit -m "feat: resize piano roll notes"
```

---

### Task 13: Add delete and selection controls

**Objective:** Provide basic editing controls.

**Files:**

- Modify: `ComposerView.swift`
- Modify: `ComposerViewModel.swift`

**Behavior:**

- Tap note selects it.
- Delete button removes selected notes.
- Clear button removes all lead notes after confirmation.

**Commit:**

```bash
git commit -m "feat: add piano roll selection controls"
```

---

### Task 14: Add playhead controller

**Objective:** Add a lightweight UI playhead separate from editor state.

**Files:**

- Create: `Topliner/Features/PianoRoll/PlayheadView.swift`
- Create: `Topliner/Services/Audio/PlayheadController.swift`

**Implementation notes:**

- Use `CADisplayLink` for UI updates.
- Long-term, poll the audio sequencer as master clock.
- Do not store fast-changing playhead state in `ProjectDocument`.

**Commit:**

```bash
git commit -m "feat: add piano roll playhead"
```

---

### Task 15: Add AudioKit dependency

**Objective:** Add audio synthesis and pitch-tracking dependencies.

**Files:**

- Modify: Xcode package dependencies or `Package.swift` if the project is converted.

**Dependencies:**

- AudioKit.
- SoundpipeAudioKit if using `PitchTap`.

**Verification:**

```bash
xcodebuild -resolvePackageDependencies -scheme Topliner
xcodebuild -scheme Topliner -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: dependencies resolve and build passes.

**Commit:**

```bash
git commit -m "chore: add AudioKit dependencies"
```

---

### Task 16: Create audio engine service

**Objective:** Centralize audio session and engine lifecycle.

**Files:**

- Create: `Topliner/Services/Audio/AudioEngineService.swift`
- Create: `ToplinerTests/Services/Audio/AudioEngineServiceTests.swift`

**Responsibilities:**

- Configure `AVAudioSession`.
- Start/stop engine.
- Manage background audio readiness later.
- Surface errors to UI.

**Commit:**

```bash
git commit -m "feat: add audio engine service"
```

---

### Task 17: Add simple wavetable/sampler playback

**Objective:** Play lead notes and chord notes locally.

**Files:**

- Create: `Topliner/Services/Audio/WavetableSynthService.swift`
- Create: `Topliner/Resources/Wavetables/default_wavetable.wav` or generate a simple oscillator fallback.

**Behavior:**

- `noteOn(pitch:velocity:)`.
- `noteOff(pitch:)`.
- `play(chord:)`.
- Basic ADSR defaults.

**Manual verification:**

- Tap note in piano roll.
- Hear local preview.
- Press Play.
- Hear all notes in time.

**Commit:**

```bash
git commit -m "feat: add local wavetable playback"
```

---

### Task 18: Add sequencer service

**Objective:** Schedule lead and chord playback against a tempo clock.

**Files:**

- Create: `Topliner/Services/Audio/SequencerService.swift`
- Add tests for event conversion where possible.

**Behavior:**

- Convert beats to seconds using BPM.
- Schedule note on/off events.
- Loop 4-bar region.
- Expose current beat for playhead.

**Commit:**

```bash
git commit -m "feat: add sequenced playback"
```

---

### Task 19: Add microphone permission and capture UI

**Objective:** Let user record mic audio.

**Files:**

- Modify: `Info.plist` microphone usage description.
- Create: `Topliner/Features/Capture/AudioCaptureView.swift`
- Create: `Topliner/Features/Capture/AudioCaptureViewModel.swift`

**Behavior:**

- Request microphone permission.
- Show record/stop state.
- Save captured buffer for pitch tracking and optional LiteRT direct-audio experiments.

**Commit:**

```bash
git commit -m "feat: add microphone capture UI"
```

---

### Task 20: Add pitch tracking service

**Objective:** Convert mic audio into raw pitch events.

**Files:**

- Create: `Topliner/Services/Audio/PitchTrackingService.swift`
- Create: `ToplinerTests/Services/Audio/PitchTrackingServiceTests.swift`

**Behavior:**

- Use AudioKit/SoundpipeAudioKit pitch tracking.
- Apply amplitude noise gate.
- Convert frequency to nearest MIDI pitch.
- Emit timestamped pitch samples.

**Core conversion:**

```swift
func midiNoteNumber(frequency: Double) -> Int {
    Int((12.0 * log2(frequency / 440.0) + 69.0).rounded())
}
```

**Tests:**

- 440 Hz maps to MIDI 69.
- 261.63 Hz maps near MIDI 60.

**Commit:**

```bash
git commit -m "feat: add pitch tracking service"
```

---

### Task 21: Convert pitch trace to draft MIDI notes

**Objective:** Segment raw pitch samples into usable notes.

**Files:**

- Create: `Topliner/Services/Audio/PitchTraceSegmenter.swift`
- Create: `ToplinerTests/Services/Audio/PitchTraceSegmenterTests.swift`

**Rules:**

- Ignore samples below amplitude threshold.
- Merge adjacent samples with same pitch if the gap is small.
- Split notes when pitch changes or amplitude drops.
- Quantize starts/durations after segmentation.
- Drop very short ghost notes.

**Commit:**

```bash
git commit -m "feat: segment pitch trace into MIDI notes"
```

---

### Task 22: Render ghost pitch trace

**Objective:** Show real-time visual feedback while recording.

**Files:**

- Create: `Topliner/Features/Capture/PitchTraceView.swift`
- Modify: `PianoRollView.swift`

**Behavior:**

- During recording, display faint line/blocks behind piano-roll notes.
- After stop, replace with quantized notes.

**Commit:**

```bash
git commit -m "feat: show pitch trace while recording"
```

---

### Task 23: Add style library JSON

**Objective:** Load harmonic styles as data.

**Files:**

- Create: `Topliner/Resources/Styles/harmonic_styles.json`
- Create: `Topliner/Services/Theory/StyleLibrary.swift`
- Create: `ToplinerTests/Services/Theory/StyleLibraryTests.swift`

**Content:**

Include initial profiles for:

- neo_soul
- jazz
- gospel_rnb
- city_pop
- bossa_nova
- blues
- funk
- synthwave
- cinematic

**Tests:**

- JSON loads.
- Every style has at least one progression seed.
- Every style has prompt instructions.

**Commit:**

```bash
git commit -m "feat: add harmonic style library"
```

---

### Task 24: Add chord-generation provider protocol and mock provider

**Objective:** Build UI and validation independent of real LiteRT integration.

**Files:**

- Create: `Topliner/Services/Inference/ChordGenerationProvider.swift`
- Create: `Topliner/Services/Inference/MockChordGenerationProvider.swift`
- Create: `ToplinerTests/Services/Inference/MockChordGenerationProviderTests.swift`

**Behavior:**

- Mock returns deterministic chords for each style.
- Enables simulator development before model integration.

**Commit:**

```bash
git commit -m "feat: add mock chord generation provider"
```

---

### Task 25: Add prompt builder

**Objective:** Convert project state and style profile into a strict LLM prompt.

**Files:**

- Create: `Topliner/Services/Inference/PromptBuilder.swift`
- Create: `ToplinerTests/Services/Inference/PromptBuilderTests.swift`

**Tests:**

- Prompt includes melody notes.
- Prompt includes style instructions.
- Prompt demands JSON only.
- Prompt includes schema.

**Commit:**

```bash
git commit -m "feat: add chord generation prompt builder"
```

---

### Task 26: Add chord-generation response parser

**Objective:** Parse strict JSON LLM output into `ChordProgression`.

**Files:**

- Create: `Topliner/Services/Inference/ChordGenerationResponseParser.swift`
- Create: `ToplinerTests/Services/Inference/ChordGenerationResponseParserTests.swift`

**Tests:**

- Parses valid JSON.
- Rejects missing chords.
- Rejects invalid MIDI values.
- Rejects non-grid-aligned starts unless correction mode is enabled.

**Commit:**

```bash
git commit -m "feat: parse chord generation responses"
```

---

### Task 27: Add chord symbol parser

**Objective:** Parse common chord symbols for validation and MIDI generation.

**Files:**

- Create: `Topliner/Services/Theory/ChordSymbolParser.swift`
- Create: `ToplinerTests/Services/Theory/ChordSymbolParserTests.swift`

**Initial supported symbols:**

- `C`, `Cm`, `Cmaj7`, `Cm7`, `C7`, `Cdim7`, `Cø7`
- `Cmaj9`, `Cm9`, `C9`, `C11`, `Cm11`, `C13`, `C13sus`
- Accidentals: `Db`, `C#`, etc.

**Commit:**

```bash
git commit -m "feat: add chord symbol parser"
```

---

### Task 28: Add chord voicer

**Objective:** Generate playable MIDI voicings with smooth voice leading.

**Files:**

- Create: `Topliner/Services/Theory/ChordVoicer.swift`
- Create: `ToplinerTests/Services/Theory/ChordVoicerTests.swift`

**Rules:**

- Default chord range: C3 to C5.
- Keep common tones when possible.
- Minimize total voice movement from prior chord.
- Optional bass root below voicing.
- Style can choose close, drop-2-like, or open voicing.

**Commit:**

```bash
git commit -m "feat: add chord voicing engine"
```

---

### Task 29: Add chord validator

**Objective:** Guard against invalid or poor LLM output.

**Files:**

- Create: `Topliner/Services/Theory/ChordValidator.swift`
- Create: `ToplinerTests/Services/Theory/ChordValidatorTests.swift`

**Validation:**

- Chord timing aligns to grid.
- Notes are playable MIDI range.
- Symbols parse.
- Style disallowed extensions are flagged.
- Empty progression is rejected.

**Commit:**

```bash
git commit -m "feat: validate generated chords"
```

---

### Task 30: Build chord generation UI

**Objective:** Let user choose style and generate chords.

**Files:**

- Create: `Topliner/Features/ChordGeneration/ChordGenerationView.swift`
- Create: `Topliner/Features/ChordGeneration/ChordGenerationViewModel.swift`
- Create: `Topliner/Features/ChordGeneration/StylePickerView.swift`
- Modify: `ComposerView.swift`

**Behavior:**

- Style picker.
- Complexity selector: simple/balanced/advanced.
- Generate button.
- Loading state.
- Error display.
- Chord result lane above or below piano roll.

**Commit:**

```bash
git commit -m "feat: add chord generation UI"
```

---

### Task 31: Add LiteRTLM-Swift dependency behind provider

**Objective:** Integrate real on-device inference without coupling the app to a concrete model.

**Files:**

- Modify: project package dependencies.
- Create: `Topliner/Services/Inference/LiteRTChordGenerationProvider.swift`
- Create: `Topliner/Resources/Models/.gitkeep`

**Important notes:**

- Do not commit large model weights to git.
- Add model file paths to `.gitignore`.
- Keep mock provider selectable for tests/simulator.
- First integration target should use symbolic melody JSON as text input.
- Direct audio input should be a later provider variant after validation.

**Verification:**

- App launches without model file and shows a clear setup error.
- App can use mock provider if model is unavailable.

**Commit:**

```bash
git commit -m "feat: add LiteRT chord provider shell"
```

---

### Task 32: Validate candidate model on device

**Objective:** Prove model load time, memory use, and output quality on target hardware.

**Files:**

- Create: `docs/product/model-evaluation.md`
- Add debug-only model benchmark screen or command if useful.

**Evaluation criteria:**

- Model loads without jetsam.
- Time to first token acceptable for workflow.
- Full generation under target latency.
- JSON format reliability.
- Chord quality per style.
- App remains responsive during playback.

**Initial candidates:**

- Smaller model first for latency.
- Larger model only if quality is insufficient and memory permits.

**Commit:**

```bash
git commit -m "docs: add model evaluation notes"
```

---

### Task 33: Add MIDI output service

**Objective:** Send generated notes through Core MIDI.

**Files:**

- Create: `Topliner/Services/MIDI/MIDIOutputService.swift`
- Create: `ToplinerTests/Services/MIDI/MIDIOutputServiceTests.swift`

**Behavior:**

- Create Core MIDI client.
- Create output port.
- Send note on/off.
- Send chords.
- Route lead/chords/both based on user setting.

**Commit:**

```bash
git commit -m "feat: add Core MIDI output service"
```

---

### Task 34: Add Bluetooth MIDI pairing UI

**Objective:** Allow pairing with BLE MIDI devices or hosts.

**Files:**

- Create: `Topliner/Services/MIDI/BluetoothMIDIService.swift`
- Create: `Topliner/Features/MIDISettings/BluetoothMIDIPairingView.swift`
- Modify: `Info.plist` Bluetooth usage descriptions if required.

**Behavior:**

- Present `CABTMIDILocalPeripheralViewController` or appropriate Core MIDI Bluetooth UI.
- Show connection instructions.

**Commit:**

```bash
git commit -m "feat: add Bluetooth MIDI pairing"
```

---

### Task 35: Add network MIDI/RTP-MIDI support

**Objective:** Enable MIDI over WiFi where supported.

**Files:**

- Create: `Topliner/Services/MIDI/NetworkMIDIService.swift`
- Modify: `MIDISettingsView.swift`

**Behavior:**

- Enable `MIDINetworkSession.default()`.
- Allow user to toggle connection policy.
- Show local network instructions for macOS/DAW setup.

**Commit:**

```bash
git commit -m "feat: add network MIDI support"
```

---

### Task 36: Add MIDI settings screen

**Objective:** Let users configure MIDI routing.

**Files:**

- Create: `Topliner/Features/MIDISettings/MIDISettingsView.swift`
- Modify: app navigation.

**Controls:**

- Send lead notes: on/off.
- Send chord notes: on/off.
- MIDI channel.
- Bluetooth pairing.
- Network MIDI enable.
- Test note button.

**Commit:**

```bash
git commit -m "feat: add MIDI settings screen"
```

---

### Task 37: Add MIDI file export

**Objective:** Export lead and chord progression as a standard MIDI file.

**Files:**

- Create: `Topliner/Services/MIDI/MIDIFileExporter.swift`
- Create: `ToplinerTests/Services/MIDI/MIDIFileExporterTests.swift`

**Behavior:**

- Export type 1 MIDI file with separate lead and chords tracks.
- Include tempo metadata.
- Use iOS share sheet.

**Commit:**

```bash
git commit -m "feat: export MIDI files"
```

---

### Task 38: Add local project persistence

**Objective:** Save and load sketches locally.

**Files:**

- Create: `Topliner/Services/ProjectStore.swift`
- Create: `Topliner/Features/ProjectBrowser/ProjectBrowserView.swift`
- Create: `Topliner/Features/ProjectBrowser/ProjectBrowserViewModel.swift`

**Behavior:**

- Store project JSON in app documents directory.
- List saved projects.
- Duplicate/delete project.
- Auto-save after edits with debounce.

**Commit:**

```bash
git commit -m "feat: add local project persistence"
```

---

### Task 39: Add project and technical docs

**Objective:** Capture product and architecture decisions in repo-visible documentation.

**Files:**

- Create: `docs/product/product-requirements.md`
- Create: `docs/product/technical-architecture.md`

**Contents:**

- Product vision.
- MVP scope.
- User flows.
- System architecture.
- Inference strategy.
- Audio/MIDI strategy.
- Style system.
- Risks and open questions.

**Commit:**

```bash
git commit -m "docs: add product and architecture documentation"
```

---

### Task 40: Add end-to-end smoke test checklist

**Objective:** Define manual verification for the MVP.

**Files:**

- Create: `docs/testing/mvp-smoke-test.md`

**Checklist:**

1. Create a project.
2. Tap notes into piano roll.
3. Play lead locally.
4. Generate mock chords.
5. Play chords locally.
6. Record mic phrase.
7. Convert to notes.
8. Edit converted notes.
9. Generate style-specific chords.
10. Export MIDI file.
11. Pair Bluetooth MIDI.
12. Send test note to DAW.
13. Enable network MIDI.
14. Record MIDI in DAW.
15. Save project.
16. Relaunch app.
17. Load project.

**Commit:**

```bash
git commit -m "docs: add MVP smoke test checklist"
```

---

## 9. Testing Strategy

### Unit tests

Prioritize pure logic:

- `Quantizer`
- `PianoRollGeometry`
- `ChordSymbolParser`
- `ChordVoicer`
- `ChordValidator`
- `PromptBuilder`
- `ChordGenerationResponseParser`
- `PitchTraceSegmenter`
- `MIDIFileExporter`
- Project persistence

### Integration tests

- Mock chord generation from a known melody.
- Chord JSON parse -> validation -> voicing -> playback event conversion.
- Lead buffer save/load.

### UI tests

- Create project.
- Add note in piano roll.
- Generate mock chords.
- Open MIDI settings.

### Manual tests

- Real microphone capture.
- Real device memory behavior.
- Real Bluetooth MIDI pairing.
- Real network MIDI to macOS DAW.
- Real LiteRT-LM inference latency and stability.

---

## 10. Performance Targets

### MVP targets

- Piano-roll editing remains visually smooth at 60 FPS for at least 200 notes.
- Local note preview feels immediate.
- Mock generation returns instantly.
- Real model generation should start streaming or show progress within 2 seconds if possible.
- Playback scheduling should not drift noticeably over a 4-bar loop.
- App should survive recording plus playback plus model inference on target device.

### Watch points

- Model RAM usage.
- AudioKit engine lifecycle bugs.
- SwiftUI redraw frequency in piano roll.
- Core MIDI connection lifecycle.
- JSON output reliability from the model.

---

## 11. Risks and Mitigations

### Risk: Direct audio-to-chords model path is not reliable enough

Mitigation:

- MVP uses deterministic pitch tracking into `LeadVoiceBuffer`.
- Keep direct audio inference behind a separate provider.
- Let users edit captured notes before generation.

### Risk: LiteRT-LM model memory exceeds practical iOS limits

Mitigation:

- Start with the smallest acceptable model.
- Keep mock provider and symbolic prompt path.
- Benchmark on real hardware early.
- Do not load model until needed.
- Release model resources when possible.

### Risk: LLM emits invalid chords or malformed JSON

Mitigation:

- Strict JSON schema in prompt.
- Parser rejects malformed output.
- Validator checks timing, pitch ranges, and chord symbols.
- Voicer can regenerate MIDI notes from chord symbols.
- UI offers regenerate and simplify options.

### Risk: Piano-roll interaction becomes complex

Mitigation:

- Keep MVP monophonic lead only.
- Use simple tap, drag, resize, delete.
- Avoid full DAW features.
- Build geometry and view model tests before UI complexity.

### Risk: Wireless MIDI latency or jitter

Mitigation:

- Provide both BLE and RTP-MIDI.
- Let users export MIDI file as fallback.
- Later add Ableton Link or external clock sync.

---

## 12. Open Decisions

1. Minimum iOS version.
2. Minimum target hardware.
3. Whether to use Xcode project directly or XcodeGen/Tuist.
4. Exact LiteRTLM-Swift API shape after dependency validation.
5. Initial model candidate and quantization format.
6. Whether the first public build includes real on-device LLM or ships with mocked/local rule-based generation first.
7. Whether chord playback should use a simple internal synth only or allow SoundFont import.
8. Whether style profiles should be editable by users.

---

## 13. Recommended Build Order

1. Project skeleton.
2. Core models.
3. Quantizer and piano-roll geometry.
4. Piano-roll rendering and editing.
5. Local playback.
6. Mock chord generation.
7. Chord parsing/validation/voicing.
8. Chord generation UI.
9. Microphone capture and pitch tracking.
10. MIDI output and export.
11. LiteRT-LM integration.
12. Real device optimization.

This order keeps the app usable early. The piano roll plus mock generation can validate UX before the hardest model and audio-capture work begins.

---

## 14. First Milestone Definition

Milestone 1 is complete when:

1. A user can open the app.
2. A user can tap a 4-bar melody into the piano roll.
3. A user can play the melody locally.
4. A user can choose Neo-Soul.
5. A mock provider generates a plausible chord progression.
6. The chords render in the UI.
7. The chords play locally.
8. Unit tests pass.

Suggested milestone commit/tag:

```bash
git tag mvp-milestone-1-piano-roll-mock-harmony
```

---

## 15. Second Milestone Definition

Milestone 2 is complete when:

1. User can record a hummed melody.
2. App shows a ghost pitch trace.
3. App converts the recording into editable MIDI notes.
4. User can clean up notes in the piano roll.
5. Mock chord generation still works from captured notes.
6. Tests for pitch conversion and segmentation pass.

---

## 16. Third Milestone Definition

Milestone 3 is complete when:

1. App can send lead and chord MIDI over Core MIDI.
2. Bluetooth MIDI pairing is accessible.
3. Network MIDI can be enabled.
4. User can export a MIDI file.
5. DAW smoke test passes on real hardware.

---

## 17. Fourth Milestone Definition

Milestone 4 is complete when:

1. LiteRTLM-Swift is integrated behind `ChordGenerationProvider`.
2. A local model can generate strict JSON from symbolic melody input.
3. Generated chords pass validation.
4. Memory and latency are documented on target device.
5. Mock provider remains available for tests.

---

## 18. Execution Handoff

Plan complete. To execute, implement one task at a time with TDD where practical, commit after each task, and keep the app buildable after every commit.

Recommended next action:

Start with Task 1 and create the iOS project skeleton. Then implement Tasks 2-6 before touching UI so the musical data foundation is tested.
