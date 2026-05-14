# Topliner technical architecture

## Overview

Topliner is an iOS 18 app built around a local SwiftPM-compatible core module. The architecture keeps model, service, parsing, validation, layout, and view-model behavior testable through headless `swift test`, while XcodeGen generates the iOS project for app compilation.

The MVP is intentionally local-first: project data is stored as JSON on device, inference falls back to deterministic mock generation when a real model is unavailable, and MIDI export/output use local iOS capabilities.

## Repository shape

- `Topliner/Models`: Codable domain models such as `ProjectDocument`, `MIDINoteEvent`, `LeadVoiceBuffer`, and `ChordProgression`.
- `Topliner/Services`: audio, inference, theory, MIDI, and project persistence services.
- `Topliner/Features`: SwiftUI views and observable view models grouped by app feature.
- `Topliner/Resources`: bundled style JSON and local-only model resource placeholder directories.
- `Tests/ToplinerCoreTests`: SwiftPM tests for pure logic and view-model/service behavior.
- `project.yml`: XcodeGen source of truth for the iOS project.
- `Package.swift`: SwiftPM harness exposing app core files as `ToplinerCore`.

## App navigation

The app uses a `TabView` with independent `NavigationStack`s:

- Compose: piano roll, playback controls, chord generation, MIDI export.
- Capture: microphone capture and pitch trace visualization.
- Projects: local project browser and project store operations.
- MIDI: routing, channel, test note, Bluetooth MIDI, and Network MIDI settings.

## Domain model

### ProjectDocument

`ProjectDocument` is the top-level persistence unit. It stores:

- UUID identity.
- title and timestamps.
- BPM, beats per bar, and total bars.
- optional key/scale.
- `LeadVoiceBuffer`.
- optional `ChordProgression`.

Projects are encoded as pretty-printed, sorted-key JSON files under the app documents directory.

### Lead and chord data

- `MIDINoteEvent` stores pitch, start beat, duration, and velocity.
- `LeadVoiceBuffer` stores note arrays, source, and quantization grid.
- `ChordProgression` stores style ID, key, chord events, and optional explanation.
- `ChordEvent` stores symbol, root MIDI note, chord MIDI notes, timing, roman numeral, and confidence.

## Audio and pitch pipeline

The capture pipeline is protocol-friendly and testable:

1. `AudioCaptureViewModel` coordinates permission, recording lifecycle, and captured buffers.
2. `AudioEngineService` owns audio-session and engine start/stop behavior behind abstractions.
3. `PitchTrackingService` converts audio/pitch observations into pitch samples.
4. `PitchTraceSegmenter` groups usable samples into quantized MIDI notes.
5. Pitch trace and piano-roll layout code stays deterministic for SwiftPM testing.

AudioKit and SoundpipeAudioKit are dependencies, but tests avoid requiring live device audio.

## Piano roll and playback

The piano roll splits UI from deterministic geometry:

- Geometry maps beats and MIDI pitches to normalized/canvas coordinates.
- Grid metrics generate beat and pitch guide lines.
- Note layout computes note rectangles, selected state, and resize handles.
- `ComposerViewModel` handles tap, drag, resize, delete, and clear operations.
- `PlayheadController` tracks current beat and looping playback state.
- `SequencerService` schedules lead and chord note-on/off events by beat.
- `WavetableSynthService` supports local synth preview.

## Chord generation pipeline

Chord generation is provider-based:

1. `ChordGenerationViewModel` builds a request from melody notes, style, key, BPM, and total beats.
2. `ChordGenerationPromptBuilder` creates symbolic melody JSON plus style instructions.
3. A provider implementing `ChordGenerationProviding` returns a `ChordProgression`.
4. `ChordGenerationResponseParser` converts strict JSON text into model objects when using LLM-like providers.
5. `ChordValidator` checks empty output, timing grid alignment, MIDI ranges, parseable symbols, and style-profile constraints.
6. `ChordSymbolParser` and `ChordVoicer` support theory operations and playable voicings.

### Providers

- `MockChordGenerationProvider`: deterministic, testable, default-safe provider.
- `LiteRTChordGenerationProvider`: on-device provider shell for a future LiteRTLM runtime; validates model presence and uses prompt-builder output.
- `ChordGenerationProviderFactory`: chooses real or mock provider based on resource availability.

The app must remain functional without model weights.

## Inference strategy

The first real inference target is a local `.litertlm` model stored outside git and copied into `Topliner/Resources/Models/topliner-chord-model.litertlm` for local testing.

Model integration rules:

- Never commit model weights.
- Keep mock fallback available.
- Use symbolic melody JSON before considering direct audio input.
- Require parser and validator pass rates before making the model default.
- Record physical-device latency and memory results in `docs/product/model-evaluation.md`.

## Style system

Styles are bundled as JSON under `Topliner/Resources/Styles/harmonic_styles.json` and loaded through `StyleLibrary` using `Bundle.module` for SwiftPM and `Bundle.main` for the app.

Each style includes:

- ID and display name.
- prompt instructions.
- seed progressions.
- optional validation profile mapping through `ChordValidationStyleProfile`.

The style system drives mock output, prompt construction, and validation constraints.

## MIDI architecture

### Real-time output

`MIDIOutputService` forms raw MIDI packets and delegates to `MIDIPacketSending`:

- Tests use fake packet sinks.
- App code uses `CoreMIDIPacketSink`.
- Output can route lead notes, chord notes, or both.
- Values are clamped to MIDI-safe ranges.
- The Core MIDI sink safely no-ops when no destination is selected.

### Bluetooth MIDI

`BluetoothMIDIService` tracks presentation state and instructions. `BluetoothMIDIPairingView` presents CoreAudioKit Bluetooth MIDI pairing controllers on iOS and a safe fallback elsewhere.

### Network MIDI

`NetworkMIDIService` wraps `MIDINetworkSession.default()` behind `NetworkMIDISessionManaging`, supports enable/disable, exposes connection policy, and documents macOS Audio MIDI Setup flow.

### MIDI file export

`MIDIFileExporter` writes a type-1 Standard MIDI File:

- Track 0: conductor/tempo metadata.
- Track 1: lead note events.
- Track 2: chord note events.
- PPQ: 480 ticks per quarter note.
- SwiftUI export uses `ShareLink` with a temporary `.mid` file.

## Persistence architecture

`ProjectStore` handles local JSON persistence:

- Default directory: app documents `Projects` directory.
- `save(_:)`: writes pretty JSON and updates timestamp.
- `load(id:)`: decodes one document.
- `list()`: loads all projects and sorts by `updatedAt` descending.
- `duplicate(id:)`: copies project content with new ID and title suffix.
- `delete(id:)`: removes the project file.

`ProjectBrowserViewModel` wraps store operations for UI refresh and error display.

Auto-save after edits is a required product behavior and should be integrated by observing editor-state changes and debouncing calls into `ProjectStore.save(_:)`.

## Testing strategy

- Use strict TDD for core services and view models.
- Prefer SwiftPM tests for pure logic, parsing, validation, layout, and service behavior.
- Run focused test first, then full `swift test`.
- Run `git diff --check` before commit.
- Regenerate Xcode project with `xcodegen generate`.
- Run generic iOS Simulator compile gate with `xcodebuild`.

## Current risks

- Real LiteRTLM Swift package/API is not yet linked.
- Real model quality and device performance remain unvalidated.
- Core MIDI destination selection may need a richer endpoint picker.
- Auto-save debounce is not yet wired to all editing flows.
- Bluetooth/Network MIDI require physical-device and DAW validation beyond compile tests.
