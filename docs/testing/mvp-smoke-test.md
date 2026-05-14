# Topliner MVP smoke test checklist

Use this checklist for manual MVP validation on a physical iOS device whenever possible. Simulator validation is acceptable only for UI/navigation checks that do not require microphone, Bluetooth MIDI, Network MIDI, or DAW recording.

## Preconditions

- App builds from the current branch with XcodeGen-generated project files.
- No credentials or private model weights are committed.
- If testing real chord inference, copy the local model file outside git into `Topliner/Resources/Models/topliner-chord-model.litertlm`; otherwise verify mock fallback behavior.
- Have a DAW or MIDI monitor available for Bluetooth/Network MIDI checks.
- Have microphone permission available on the test device.

## Build verification

- [ ] Run `swift test` and confirm all tests pass.
- [ ] Run `git diff --check` and confirm no whitespace issues.
- [ ] Run `xcodegen generate`.
- [ ] Run the generic iOS Simulator compile gate with `xcodebuild`.
- [ ] Install and launch the app on the target device.

## End-to-end MVP flow

### 1. Create a project

- [ ] Open the Projects tab.
- [ ] Tap New Project.
- [ ] Confirm a new project appears in the list.
- [ ] Confirm the project title, BPM, and bar count are visible.

Expected result: a project JSON file can be created locally and listed without errors.

### 2. Tap notes into piano roll

- [ ] Open the Compose tab.
- [ ] Tap several empty piano-roll positions.
- [ ] Confirm notes appear at quantized beats and expected pitches.
- [ ] Select an existing note.
- [ ] Drag it to a different pitch/start beat.
- [ ] Resize its duration.
- [ ] Delete one selected note.

Expected result: note edit operations are responsive and visually reflected in the piano roll.

### 3. Play lead locally

- [ ] Tap Play.
- [ ] Confirm the playhead moves.
- [ ] Confirm lead notes trigger local playback or at minimum scheduled playback state updates.
- [ ] Tap Stop.
- [ ] Tap Reset.

Expected result: playback controls respond and the playhead resets correctly.

### 4. Generate mock chords

- [ ] Select a harmonic style.
- [ ] Select a complexity.
- [ ] Tap Generate Chords.
- [ ] Confirm chord symbols appear in the chord lane.
- [ ] Confirm no parser/validator error is shown.

Expected result: mock provider returns deterministic style-specific chords and the UI stores them.

### 5. Play chords locally

- [ ] Start playback with generated chords present.
- [ ] Confirm chord events are scheduled or locally previewed with the lead.
- [ ] Stop playback.

Expected result: chord scheduling does not break lead playback or UI responsiveness.

### 6. Record mic phrase

- [ ] Open Capture.
- [ ] Grant microphone permission if prompted.
- [ ] Record a short sung or hummed phrase.
- [ ] Stop recording.
- [ ] Confirm captured buffer or pitch trace state updates.

Expected result: microphone flow completes without crashing and stores captured data.

### 7. Convert to notes

- [ ] Convert the recorded phrase into quantized MIDI notes.
- [ ] Confirm quiet/invalid input does not produce noisy notes.
- [ ] Confirm usable pitch segments become MIDI note events.

Expected result: pitch trace segmentation produces editable notes aligned to the quantize grid.

### 8. Edit converted notes

- [ ] Move converted notes in the piano roll.
- [ ] Resize at least one converted note.
- [ ] Delete any bad note.

Expected result: converted notes behave the same as tapped notes.

### 9. Generate style-specific chords

- [ ] Select `neo_soul` or another extension-heavy style.
- [ ] Generate chords from the converted melody.
- [ ] Confirm extensions are accepted for compatible styles.
- [ ] Select a simpler style such as synthwave/funk/cinematic.
- [ ] Generate again and confirm output feels simpler.

Expected result: style selection influences generation and validation does not allow unsupported symbols for restricted profiles.

### 10. Export MIDI file

- [ ] Tap Export MIDI File or Prepare MIDI Export in Compose.
- [ ] Share/save the `.mid` file through the iOS share sheet.
- [ ] Open the exported file in a DAW or MIDI inspector.
- [ ] Confirm it is a type-1 MIDI file with separate conductor, lead, and chord tracks.
- [ ] Confirm tempo metadata matches project BPM.

Expected result: exported MIDI imports successfully and contains lead and chord notes.

### 11. Pair Bluetooth MIDI

- [ ] Open MIDI Settings.
- [ ] Tap Open Bluetooth MIDI Pairing.
- [ ] Pair a Bluetooth MIDI device or host.
- [ ] Dismiss the pairing sheet.

Expected result: system Bluetooth MIDI pairing UI opens and dismisses cleanly.

### 12. Send test note to DAW

- [ ] Configure MIDI channel.
- [ ] Confirm Send Lead Notes and/or Send Chord Notes toggles are set as desired.
- [ ] Tap Send Test Note.
- [ ] Confirm the DAW/MIDI monitor receives C4 on the selected channel.

Expected result: the test note reaches the selected Core MIDI destination when one is configured.

### 13. Enable network MIDI

- [ ] Open MIDI Settings.
- [ ] Enable Network MIDI.
- [ ] Choose connection policy.
- [ ] On macOS, open Audio MIDI Setup > MIDI Studio > Network.
- [ ] Create or join an RTP-MIDI session.
- [ ] Connect to the iOS device/session.

Expected result: Network MIDI can be enabled and the DAW/macOS host can see or connect to the session.

### 14. Record MIDI in DAW

- [ ] Arm a DAW MIDI track.
- [ ] Start playback or send notes from Topliner.
- [ ] Record incoming MIDI.
- [ ] Confirm timing, pitch, and channel are correct.

Expected result: DAW captures lead/chord MIDI as expected.

### 15. Save project

- [ ] Return to Projects or trigger save flow.
- [ ] Confirm the current sketch exists in the project list.
- [ ] Duplicate the project.
- [ ] Delete a duplicate.

Expected result: save/list/duplicate/delete operations work without data loss.

### 16. Relaunch app

- [ ] Force quit the app.
- [ ] Relaunch.
- [ ] Open Projects.

Expected result: saved projects are still listed after relaunch.

### 17. Load project

- [ ] Open a saved project.
- [ ] Confirm title, BPM, key, lead notes, and chord progression are preserved.
- [ ] Play or export again to verify loaded data is usable.

Expected result: project JSON round-trips the musical sketch correctly.

## Regression notes

Record failures with:

- device model and iOS version
- app commit SHA
- exact step number
- expected vs actual result
- screenshot or screen recording if UI-related
- DAW/MIDI monitor evidence for MIDI issues

## Pass criteria

The MVP smoke test passes when:

- All build verification steps pass.
- Steps 1 through 17 complete without crashes.
- Exported MIDI imports in a DAW.
- At least one external MIDI path, Bluetooth or Network, is validated on physical hardware.
- Any deferred limitations are documented as known issues rather than silent failures.
