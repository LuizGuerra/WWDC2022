import Foundation
import SpriteKit

// Super class
public class NodeConfigurations: SKScene {
    var nextSKScene: SKScene? { nil }
    
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
    
    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        setIfWon()
        setIfLost()
//        if won {
//            setIfWon()
//        } else {
//            setIfLost()
//        }
    }
    
    private func setIfWon() {
        guard let sprite = childNode(withName: "defense_cell") as? SKSpriteNode else { return }
        var textureName = ""
        switch fromLevel {
        case 1:
            textureName = "Asset_Macrophage"
        case 2:
            textureName = "Asset_Neutrophil"
        case 3:
            textureName = "Asset_HelperT"
        case 4:
            textureName = "Asset_HelperB"
        default:
            break
        }
        let newTexture = SKTexture(imageNamed: textureName)
        sprite.run(.setTexture(newTexture, resize: true))
    }
    
    private func setIfLost() {
        guard let descriptionNode = childNode(withName: "description") as? SKSpriteNode else {
            return
        }
        var textureName = "Asset_LevelFailed_Description"
        if fromLevel == 1 {
            textureName += "1"
        }
        if fromLevel == 2 || fromLevel == 3 {
            textureName += "2-3"
        }
        if fromLevel == 4 {
            textureName += "4"
        }
        let newTexture = SKTexture(imageNamed: textureName)
        descriptionNode.run(.setTexture(newTexture, resize: true))
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
