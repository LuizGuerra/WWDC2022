import Foundation
import SpriteKit

// Super class
public class NodeConfigurations: SKScene {
    var nextSKScene: SKScene? { nil }

    
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

public class LevelEndConfigurations: SKScene {
    var won: Bool = true
    var fromLevel: Int = 1
    
    public func configure(won: Bool, from level: Int) {
        self.won = won
        self.fromLevel = level
    }

    // If won
    var levelCompletedTexture: String? { nil }
    
    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        if won {
            setIfWon()
        } else {
            setIfLost()
        }
    }
    
    private func setIfWon() {
        guard let sprite = childNode(withName: "defense_cell") as? SKSpriteNode,
              let textureName = levelCompletedTexture else { return }
        sprite.texture = SKTexture(imageNamed: textureName)
    }
    
    private func setIfLost() {
        guard let helpLabel = childNode(withName: "help_text") as? SKLabelNode else {
            return
        }
        if fromLevel == 4 {
            helpLabel.text = "Tap anywhere in the screen to produce anti-bodies and eliminate all the dangerous cells!"
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if won {
            navigateToNext()
        } else {
            replayLevel()
        }
    }
    
    private func replayLevel() {
        var levelScene: Level?
        switch fromLevel {
        case 1:
            levelScene = LevelOneScene(fileNamed: "04_Level01")
        case 2:
            levelScene = LevelTwoScene(fileNamed: "06_Level02")
        case 3:
            levelScene = LevelThreeScene(fileNamed: "09_Level03")
        case 4:
            levelScene = LevelFourScene(fileNamed: "11_Level04")
        default: break
        }
        guard let levelScene = levelScene else {
            return
        }
        let moveRight = SKTransition.moveIn(with: .right, duration: 0.4)
        levelScene.scaleMode = .aspectFit
        view?.presentScene(levelScene, transition: moveRight)
    }
    
    private func navigateToNext() {
        var nextSKScene: NodeConfigurations?
        switch fromLevel {
        case 1:
            nextSKScene = NeutrophilScene(fileNamed: "05_Neutrophil")
        case 2:
            nextSKScene = DentriticScene(fileNamed: "07_Dentritic")
        case 3:
            nextSKScene = HelperBScene(fileNamed: "10_HelperB")
        case 4:
            nextSKScene = GameCompleted(fileNamed: "12_End")
        default: break
        }
        guard let nextSKcene = nextSKScene else {
            return
        }
        let moveRight = SKTransition.moveIn(with: .right, duration: 0.4)
        nextSKcene.scaleMode = .aspectFit
        view?.presentScene(nextSKcene, transition: moveRight)
    }
}
