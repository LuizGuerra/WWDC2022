import Foundation
import SpriteKit

// Super class
public class NodeConfigurations: SKScene {
    var nextSKScene: SKScene? { nil }
    
//    public override func didMove(to view: SKView) {
//
//    }
//    func buildView() {}
//    func animate() {}
    
//    func animateDown(_ node: SKNode) {
////        let action = SKAction.sequence([
////
////        ])
//    }
    
//    func animateUp(_ node: SKNode) {
//
//    }
    
//    func setTexts(_ node: SKLabelNode, _ text: String) {
//        node.text = text
//        node.numberOfLines = 0
//        node.lineBreakMode = .byWordWrapping
//        node.preferredMaxLayoutWidth = 500
//    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let nextSKScene = nextSKScene else { return }
        navigate(to: nextSKScene)
    }

    private func navigate(to scene: SKScene) {
        guard let view = view else { return }
        scene.scaleMode = .aspectFit
        view.presentScene(scene, transition: SKTransition.moveIn(with: .right, duration: 0.4))
    }
}
