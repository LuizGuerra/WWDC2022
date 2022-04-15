import Foundation
import SpriteKit
import AVFoundation

public class Game {
    public static func start(action: (_ scene: SKView) -> Void) {
        let sceneKitView = SKView(frame: CGRect(x: 0, y: 0, width: 720, height: 540))
        guard let scene = HomeScene(fileNamed: "01_Home") else { return }
        
        scene.scaleMode = .aspectFit
        sceneKitView.presentScene(scene)
        
        action(sceneKitView)
    }
}
