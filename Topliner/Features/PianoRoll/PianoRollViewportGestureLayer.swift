import CoreGraphics
import SwiftUI

#if canImport(UIKit)
import UIKit

final class MultiTouchPassthroughView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let touchCount = event?.allTouches?.count ?? 0
        return touchCount >= 2 && super.point(inside: point, with: event)
    }
}

struct PianoRollViewportGestureLayer: UIViewRepresentable {
    var onPan: (CGSize, CGSize) -> Void
    var onZoom: (Double, CGPoint, CGSize) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPan: onPan, onZoom: onZoom)
    }

    func makeUIView(context: Context) -> UIView {
        let view = MultiTouchPassthroughView(frame: .zero)
        view.backgroundColor = .clear
        view.isMultipleTouchEnabled = true

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)

        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        pinch.delegate = context.coordinator
        view.addGestureRecognizer(pinch)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onPan = onPan
        context.coordinator.onZoom = onZoom
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onPan: (CGSize, CGSize) -> Void
        var onZoom: (Double, CGPoint, CGSize) -> Void

        init(onPan: @escaping (CGSize, CGSize) -> Void, onZoom: @escaping (Double, CGPoint, CGSize) -> Void) {
            self.onPan = onPan
            self.onZoom = onZoom
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let view = recognizer.view else { return }
            let translation = recognizer.translation(in: view)
            onPan(CGSize(width: translation.x, height: translation.y), view.bounds.size)
            recognizer.setTranslation(.zero, in: view)
        }

        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            guard let view = recognizer.view else { return }
            let anchor = recognizer.location(in: view)
            onZoom(Double(recognizer.scale), anchor, view.bounds.size)
            recognizer.scale = 1
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
#else
struct PianoRollViewportGestureLayer: View {
    var onPan: (CGSize, CGSize) -> Void
    var onZoom: (Double, CGPoint, CGSize) -> Void

    var body: some View {
        Color.clear
            .allowsHitTesting(false)
    }
}
#endif
