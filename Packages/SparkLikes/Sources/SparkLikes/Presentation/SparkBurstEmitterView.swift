// Module: SparkLikes — Heart particle burst on spark action (CAEmitterLayer).

import SwiftUI
import UIKit

struct SparkBurstEmitterView: UIViewRepresentable {
    let trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeUIView(context: Context) -> SparkBurstUIView {
        SparkBurstUIView()
    }

    func updateUIView(_ uiView: SparkBurstUIView, context: Context) {
        guard trigger > 0, !reduceMotion else { return }
        uiView.burst()
    }
}

final class SparkBurstUIView: UIView {
    private let emitterLayer = CAEmitterLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.addSublayer(emitterLayer)
        emitterLayer.emitterShape = .point
        emitterLayer.renderMode = .additive
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        emitterLayer.frame = bounds
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
    }

    func burst() {
        emitterLayer.emitterCells = [heartCell()]
        emitterLayer.birthRate = 1
        Task { @MainActor [weak self] in
            // REASONING: Cancellation ends the burst early; no user-facing error.
            try? await Task.sleep(for: .milliseconds(800))
            self?.emitterLayer.birthRate = 0
        }
    }

    private func heartCell() -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.contents = UIImage(systemName: "heart.fill")?
            .withTintColor(.systemPink, renderingMode: .alwaysOriginal)
            .cgImage
        cell.birthRate = 40
        cell.lifetime = 0.8
        cell.velocity = 180
        cell.velocityRange = 80
        cell.emissionRange = .pi * 2
        cell.scale = 0.12
        cell.scaleRange = 0.06
        cell.alphaSpeed = -1.2
        cell.spinRange = 2
        return cell
    }
}

#Preview {
    SparkBurstEmitterView(trigger: 1)
        .frame(width: 200, height: 200)
}
