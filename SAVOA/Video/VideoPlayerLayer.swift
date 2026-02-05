//
//  VideoPlayerLayer.swift
//  PelvicFloorApp
//
//  Created by 7Я on 12.12.2025.
//

import SwiftUI
import AVKit

struct VideoPlayerLayer: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        return view
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        if uiView.playerLayer.player != player {
            uiView.playerLayer.player = player
        }
    }
}

final class PlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
