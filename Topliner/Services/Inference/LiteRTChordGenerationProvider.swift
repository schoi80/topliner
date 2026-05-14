import Foundation

enum LiteRTChordGenerationProviderError: Error, Equatable, LocalizedError {
    case modelFileMissing(String)
    case unknownStyle(String)
    case runtimeUnavailable
    case invalidModelOutput(String)

    var errorDescription: String? {
        switch self {
        case .modelFileMissing(let path):
            return "LiteRT model file is missing at \(path). Add a .litertlm model file under Topliner/Resources/Models or use the mock provider."
        case .unknownStyle(let styleID):
            return "Unknown style: \(styleID)"
        case .runtimeUnavailable:
            return "LiteRT runtime is not linked yet. Use the mock provider until LiteRTLM-Swift is available."
        case .invalidModelOutput(let details):
            return "LiteRT model output could not be parsed: \(details)"
        }
    }
}

final class LiteRTChordGenerationProvider: ChordGenerationProviding {
    var modelURL: URL
    var styleLibrary: StyleLibrary
    var promptBuilder: ChordGenerationPromptBuilder
    var responseParser: ChordGenerationResponseParser
    private(set) var lastPrompt: String?

    init(
        modelURL: URL = LiteRTChordGenerationProvider.defaultModelURL(),
        styleLibrary: StyleLibrary,
        promptBuilder: ChordGenerationPromptBuilder = ChordGenerationPromptBuilder(),
        responseParser: ChordGenerationResponseParser = ChordGenerationResponseParser(correctionMode: .quantizeToGrid)
    ) {
        self.modelURL = modelURL
        self.styleLibrary = styleLibrary
        self.promptBuilder = promptBuilder
        self.responseParser = responseParser
    }

    static func defaultModelURL() -> URL {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle.main
        #endif

        if let resourceURL = bundle.url(
            forResource: "topliner-chord-model",
            withExtension: "litertlm",
            subdirectory: "Models"
        ) {
            return resourceURL
        }

        return bundle.bundleURL
            .appendingPathComponent("Models", isDirectory: true)
            .appendingPathComponent("topliner-chord-model.litertlm")
    }

    func generateProgression(for request: ChordGenerationRequest) throws -> ChordProgression {
        guard FileManager.default.fileExists(atPath: modelURL.path) else {
            throw LiteRTChordGenerationProviderError.modelFileMissing(modelURL.path)
        }

        guard let style = styleLibrary.style(id: request.styleID) else {
            throw LiteRTChordGenerationProviderError.unknownStyle(request.styleID)
        }

        let prompt = promptBuilder.buildPrompt(request: request, style: style)
        lastPrompt = prompt

        let output = try runLiteRTRuntime(prompt: prompt)
        do {
            return try responseParser.parse(output)
        } catch {
            throw LiteRTChordGenerationProviderError.invalidModelOutput(error.localizedDescription)
        }
    }

    private func runLiteRTRuntime(prompt: String) throws -> String {
        _ = prompt
        #if canImport(LiteRTLM)
        // Future integration point: instantiate LiteRTLM-Swift with modelURL and run prompt text generation.
        throw LiteRTChordGenerationProviderError.runtimeUnavailable
        #else
        throw LiteRTChordGenerationProviderError.runtimeUnavailable
        #endif
    }
}

enum ChordGenerationProviderFactory {
    static func makeDefaultProvider(
        styleLibrary: StyleLibrary,
        modelURL: URL = LiteRTChordGenerationProvider.defaultModelURL(),
        preferLiteRT: Bool = false
    ) -> any ChordGenerationProviding {
        if preferLiteRT, FileManager.default.fileExists(atPath: modelURL.path) {
            return LiteRTChordGenerationProvider(modelURL: modelURL, styleLibrary: styleLibrary)
        }
        return MockChordGenerationProvider(styleLibrary: styleLibrary)
    }
}
