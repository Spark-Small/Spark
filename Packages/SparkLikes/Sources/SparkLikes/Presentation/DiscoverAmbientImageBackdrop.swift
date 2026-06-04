// Module: SparkLikes — Photos-style ambient fill (system blur, not SwiftUI blur radius).

import SwiftUI
import UIKit

struct DiscoverAmbientImageBackdrop: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> DiscoverAmbientBackdropUIView {
        DiscoverAmbientBackdropUIView()
    }

    func updateUIView(_ uiView: DiscoverAmbientBackdropUIView, context: Context) {
        uiView.setImage(image)
    }
}

@MainActor
final class DiscoverAmbientBackdropUIView: UIView {
    private let imageView = UIImageView()
    private let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        addSubview(effectView)
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        effectView.frame = bounds
    }

    func setImage(_ image: UIImage) {
        imageView.image = image
    }
}
