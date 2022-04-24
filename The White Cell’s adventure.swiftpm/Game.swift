import Foundation
import SpriteKit
import AVFoundation

public class Game {    
    public static func getGameScene() -> SKScene {
        guard let scene = HomeScene(fileNamed: "01_Home") else {
            print("problem at paradise")
            return SKScene()
        }
        print("no prob bob")
        startMusic(in: scene)
        scene.scaleMode = .aspectFit
        return scene
    }
    
    private static func startMusic(in scene: SKScene) {
        // Copyright free music from bensound
        let fileName = "MusicAsset_bensound-goinghigher.mp3"
        let soundAction = SKAction.playSoundFileNamed(fileName, waitForCompletion: true)
        scene.run(.repeatForever(soundAction))
    }
}
