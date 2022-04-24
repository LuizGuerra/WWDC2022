import Foundation
import SpriteKit
import AVFoundation

public class Game {
    public static func start(action: (_ scene: SKView) -> Void) {
        let sceneKitView = SKView(frame: CGRect(x: 0, y: 0, width: 720, height: 540))
        guard let scene = HomeScene(fileNamed: "01_Home") else { return }
        
        startMusic(in: scene)
        
        scene.scaleMode = .aspectFit
        sceneKitView.presentScene(scene)
        
//        sceneKitView.showsFPS = true
//        sceneKitView.showsNodeCount = true
        
        action(sceneKitView)
    }
    
    private static func startMusic(in scene: SKScene) {
        // Copyright free music from bensound
        let fileName = "MusicAsset_bensound-goinghigher.mp3"
        let soundAction = SKAction.playSoundFileNamed(fileName, waitForCompletion: true)
        scene.run(.repeatForever(soundAction))
    }
}
