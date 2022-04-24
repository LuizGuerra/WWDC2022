//#-hidden-code
import PlaygroundSupport
import SpriteKit

// Helper function since I couldn't import PlaygroundSupport in other files
func playgroundSupportAction(_ scene: SKView) {
    PlaygroundSupport.PlaygroundPage.current.liveView = scene
}
//#-end-hidden-code

/*:
 # Welcome to my playground!
 To start the game, just press the play button!
 */

Game.start(action: playgroundSupportAction)
