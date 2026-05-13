# Topliner product requirements

## Product vision

Topliner is an iOS-first sketchpad for producers, topliners, and songwriters who think in melody first. The app turns sung, hummed, or tapped-in melodic ideas into editable MIDI notes, generates style-aware chord progressions, and exports the result to DAWs or hardware over MIDI.

The core promise is fast musical momentum: capture a hook, clean it up in a piano roll, ask for harmonies in a target style, then play or export the result without leaving the phone.

## MVP scope

### In scope

- Create and manage local sketch projects.
- Tap notes into a piano-roll editor.
- Record microphone phrases and convert pitch traces into quantized notes.
- Edit note pitch, timing, duration, and selection in the piano roll.
- Generate chord progressions from melody, key, BPM, and selected harmonic style.
- Validate generated chords for timing, MIDI range, supported symbols, and style constraints.
- Preview lead and chord playback locally.
- Send lead and chord notes through Core MIDI packet output.
- Configure MIDI routing, channel, Bluetooth MIDI pairing, and Network/RTP-MIDI.
- Export a type-1 Standard MIDI File with conductor, lead, and chord tracks.
- Save project JSON locally and list/duplicate/delete saved projects.

### Out of scope for MVP

- Cloud sync or account system.
- Collaborative editing.
- Full DAW arrangement timeline.
- Audio stem recording or multitrack audio export.
- Real-time polyphonic audio-to-MIDI transcription.
- Committing model weights to git.
- Server-side inference as a default dependency.

## Target users

- Songwriters capturing topline ideas quickly.
- Producers looking for harmonic starting points around a vocal melody.
- Mobile-first musicians who want MIDI output into desktop DAWs or hardware.
- Musicians experimenting with genre-specific harmonic language.

## Primary user flows

### Create a sketch

1. Open Projects.
2. Tap New Project.
3. Open the new sketch in the compose surface.
4. Set BPM/key as the project evolves.
5. Save automatically to local JSON.

### Tap/edit a melody

1. Open Compose.
2. Tap empty piano-roll cells to add default notes.
3. Tap existing notes to select them.
4. Drag selected notes to change pitch/start beat.
5. Resize selected notes to change duration.
6. Delete or clear notes as needed.

### Record a sung idea

1. Open Capture.
2. Grant microphone permission.
3. Record a short phrase.
4. Convert pitch tracking output to quantized ghost/lead notes.
5. Refine generated notes in the piano roll.

### Generate chords

1. Choose a harmonic style.
2. Choose complexity.
3. Tap Generate.
4. The provider builds a symbolic melody prompt.
5. The provider returns a `ChordProgression`.
6. The parser and validator enforce schema, timing, MIDI, and style constraints.
7. The chord lane displays the resulting symbols.

### Export/send MIDI

1. Configure MIDI routing in MIDI Settings.
2. Choose lead/chord output and channel.
3. Pair Bluetooth MIDI or enable Network MIDI if needed.
4. Tap Send Test Note to verify the destination.
5. Export the sketch as a `.mid` file through the iOS share sheet.
6. Import or record the result in the DAW.

## Functional requirements

- FR1: The app must preserve project identity, title, timestamps, BPM, meter, key/scale, lead notes, and chord progression in JSON.
- FR2: The piano roll must support deterministic note hit testing, note layout, beat/pitch quantization, dragging, resizing, deletion, and clearing.
- FR3: Audio capture must be testable behind protocols and must not block headless SwiftPM tests.
- FR4: Pitch tracking must reject invalid/quiet samples and quantize usable segments to MIDI note events.
- FR5: Chord generation must be provider-based so mock and on-device inference providers are interchangeable.
- FR6: Generated chord output must parse from strict JSON into `ChordProgression`.
- FR7: Generated chords must be validated before use.
- FR8: MIDI output must be testable with packet-sink fakes and must safely no-op when no Core MIDI destination is selected.
- FR9: Bluetooth and Network MIDI setup must expose clear user instructions and required iOS permission strings.
- FR10: MIDI file export must produce a type-1 Standard MIDI File with separate conductor, lead, and chord tracks.

## Non-functional requirements

- NFR1: Core behavior must be covered by fast SwiftPM tests.
- NFR2: The iOS app target must compile through XcodeGen-generated project files.
- NFR3: Local project data must stay on device for MVP.
- NFR4: The app must launch without model weights and fall back to mock generation when a real model is unavailable.
- NFR5: Large model artifacts must remain out of git.
- NFR6: UI should stay responsive during capture, playback, generation, and export operations.

## Risks and open questions

- Real LiteRTLM Swift API/package availability is still unresolved; provider shell is ready but runtime binding is pending.
- On-device model latency and memory must be validated on physical hardware before enabling real inference by default.
- Core MIDI destination selection is currently foundational; richer device selection may be needed after hardware testing.
- Auto-save debounce exists as a product requirement but may need deeper integration with editing state beyond current store primitives.
- Generated harmonic quality needs human musical review across styles.
