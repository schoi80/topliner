# Topliner model evaluation notes

Status: evaluation plan ready; no candidate `.litertlm` model file is committed.

Task 32 goal: prove that an on-device chord generation model can load, generate strict JSON, and stay responsive on target iOS hardware before making it the default provider.

## Current integration state

- `LiteRTChordGenerationProvider` is a provider shell behind `ChordGenerationProviding`.
- The app remains usable without model weights because `ChordGenerationProviderFactory` falls back to `MockChordGenerationProvider` when the model file is missing.
- Expected local model path: `Topliner/Resources/Models/topliner-chord-model.litertlm`.
- Large model artifacts are intentionally ignored by git:
  - `Topliner/Resources/Models/*.litertlm`
  - `Topliner/Resources/Models/*.tflite`
  - `Topliner/Resources/Models/*.bin`
  - `Topliner/Resources/Models/*.gguf`
- The first real provider path should use symbolic melody JSON text input from `ChordGenerationPromptBuilder`; direct audio input is out of scope until text-input quality is validated.

## Candidate order

1. Smallest candidate that can reliably emit JSON.
   - Target: fastest load and generation latency.
   - Accept lower harmonic sophistication if style and schema reliability are good.
2. Larger candidate only if the smaller candidate fails quality thresholds.
   - Must stay under memory and responsiveness limits.
   - Must not interrupt audio playback or editing interactions.

## Device test matrix

Record results per physical device and model candidate.

| Device | iOS | Model | Size | Load result | Peak memory | TTFT | Full generation | JSON valid | Chord quality | Playback responsive | Notes |
| --- | --- | --- | ---: | --- | ---: | ---: | ---: | --- | --- | --- | --- |
| TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD |

Definitions:

- Load result: pass/fail plus any setup/runtime error.
- Peak memory: approximate app memory after model load and during generation.
- TTFT: time to first token or first generated output chunk.
- Full generation: elapsed time from tapping Generate to parsed `ChordProgression`.
- JSON valid: parser success rate over repeated prompts.
- Chord quality: human review against expected style and melody support.
- Playback responsive: whether playhead/audio/UI remain responsive during generation.

## Acceptance thresholds

A model candidate is acceptable for the first real-provider default only if all required criteria pass:

| Criterion | Required threshold |
| --- | --- |
| Missing model behavior | App launches and clearly falls back to mock or setup error |
| Model load | No crash, no jetsam, no UI freeze longer than 2 seconds |
| Peak memory | No system memory warning or jetsam on target device |
| TTFT | Under 2 seconds for simple melody prompts |
| Full generation | Under 6 seconds for a 16-beat progression |
| JSON validity | 95%+ parse success over 20 repeated generations |
| Validator pass rate | 90%+ `ChordValidator` pass or auto-correctable issues only |
| Style relevance | Human reviewer accepts 8/10 generations per style smoke set |
| Playback responsiveness | Existing playback remains responsive during generation |

## Prompt set for validation

Run each candidate against this smoke set using symbolic melody JSON:

1. C major, 120 BPM, 16 beats, ascending simple melody, style `neo_soul`.
2. A minor, 96 BPM, 16 beats, sparse melody, style `synthwave`.
3. F major, 110 BPM, 16 beats, syncopated melody, style `funk`.
4. D minor, 140 BPM, 32 beats, busier melody, style `jazz`.
5. C major, 72 BPM, 16 beats, long sustained melody notes, style `cinematic`.

For every output:

1. Parse with `ChordGenerationResponseParser`.
2. Validate with `ChordValidator`.
3. Confirm chord symbols parse with `ChordSymbolParser`.
4. Confirm MIDI notes are playable and align to the 0.25-beat grid.
5. Review whether the progression supports the melody and requested style.

## Manual device procedure

1. Obtain a candidate `.litertlm` file outside git.
2. Copy it to `Topliner/Resources/Models/topliner-chord-model.litertlm` locally.
3. Regenerate the project if resource membership changes:
   ```bash
   xcodegen generate
   ```
4. Build and run on the physical target device from Xcode.
5. Confirm app launch succeeds.
6. Confirm the mock provider remains selectable or available when the model file is removed.
7. Run the prompt smoke set above.
8. Record results in the device test matrix.
9. If any required threshold fails, keep mock as default and record the candidate as rejected.

## Debug benchmark recommendation

A debug-only benchmark screen or command should be added after a concrete LiteRTLM-Swift API is linked. It should report:

- model URL and file size
- load duration
- peak memory estimate
- generation duration
- parser result
- validator issues
- generated chord symbols

Until the runtime API is linked, this document is the source of truth for manual evaluation and the provider shell tests verify missing-model fallback behavior.
