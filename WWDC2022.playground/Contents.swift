import PlaygroundSupport
import SpriteKit

// Helper function since I couldn't import PlaygroundSupport in other files
func playgroundSupportAction(_ scene: SKView) {
    PlaygroundSupport.PlaygroundPage.current.liveView = scene
}

Game.start(action: playgroundSupportAction)
