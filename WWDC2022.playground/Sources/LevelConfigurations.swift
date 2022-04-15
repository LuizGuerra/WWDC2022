import SpriteKit
import GameplayKit

// MARK: Constants
fileprivate enum EntityConfigurations {
    // White Cell
    static let whiteCellName = "whiteCell"
    static let whiteCellSpeed: CGFloat = 160
    
    // Virus
    static let virusName = "virus"
    static let virusSpeed: CGFloat = 50
    static let awarenessRange: CGFloat = 200
}

public class Level: SKScene, SKPhysicsContactDelegate {
    
    // MARK: Outlets
    var whiteCell: SKSpriteNode?
    var viruses: [SKSpriteNode] = []
    var awakeViruses: [Bool] = []
    
    // MARK: Other stuff
    var lastTouch: CGPoint? = nil
    var updates: Int = 0
    var touchTimer: Timer?
    
    var canMove: Bool = true
    var isMoving: Bool = false
    
    var levelCompleted: Bool = false
    
    // Mark: Bitmask IDs
    private let DEFENSECELL = 1
    private let VIRUS = 2
    private let REDCELL = 3
    private let WALL = 4
    
    // MARK: Level computed variables
    var level: Int { 0 }
    var nextSKSCene: SKScene? { nil }
    var repeatScene: SKScene? { nil }
    
    public override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        setNodes()
    }
    
    private func setNodes() {
        whiteCell = childNode(withName: EntityConfigurations.whiteCellName) as? SKSpriteNode
        for child in self.children where child.name == "virus" {
            if let virus = child as? SKSpriteNode {
                viruses.append(virus)
                awakeViruses.append(false)
            }
        }
    }
    
    
    func updateWhiteCell() {
        guard let whiteCell = whiteCell, let touch = lastTouch else {
            return
        }
        if canMove(from: whiteCell.position, to: touch) {
            vectorialMovement(whiteCell, to: touch, speed: EntityConfigurations.whiteCellSpeed, rotate: true)
        } else {
            whiteCell.physicsBody?.isResting = true
        }

    }
    
    func stopWhiteCell() {
        guard let whiteCell = whiteCell, let pos = lastTouch else {
            return
        }
        if !canMove(from: whiteCell.position, to: pos) {
            whiteCell.physicsBody?.isResting = true
        }
    }
    
    // TODO: todo
    func updateViruses() {
        
    }
    
    private func canMove(from: CGPoint, to: CGPoint) -> Bool {
        guard let whiteCellFrame = whiteCell?.frame else {
            return false
        }
        let insideAllowedWidth = abs(from.x - to.x) > whiteCellFrame.width / 2
        let insideAllowedHeight = abs(from.y - to.y) > whiteCellFrame.height / 2
        return insideAllowedHeight || insideAllowedWidth
    }
    
//    private func virusCanMove(_ virus: SKNode) -> Bool {
//        guard let whiteCell = whiteCell else {
//            return false
//        }
//        let from = virus.position
//        let to = whiteCell.position
//        let distanceSquared = sqrt((from.x - to.x)*(from.x - to.x) + (from.y - to.y)*(from.y - to.y))
//        return distanceSquared <= 180 // (virus detection range)
//    }
    
    private func vectorialMovement(_ sprite: SKSpriteNode, to: CGPoint, speed: CGFloat, rotate: Bool = false) {
        // Movement vector calculation
        let from = sprite.position
        let angle = CGFloat.pi + atan2(from.y - to.y, from.x - to.x)
        let velocityVector = CGVector(dx: speed * cos(angle), dy: speed * sin(angle))
        // If should rotate
        if rotate {
            // moves when rotation ends
            let rotateAction = SKAction.rotate(toAngle: angle, duration: 0)
            sprite.run(rotateAction, completion: {
                sprite.removeAllActions()
                sprite.physicsBody?.velocity = velocityVector
            })
        } else {
            sprite.removeAllActions()
            sprite.physicsBody?.velocity = velocityVector
        }
    }
    
//    private func spin(_ node: SKNode) {
//        guard let spriteNode = node as? SKSpriteNode else { return }
//        let spin = SKAction.rotate(byAngle: .pi, duration: 4)
//        spriteNode.run(spin)
//    }
//
//    private func bounce(_ node: SKNode) {
//        guard let spriteNode = node as? SKSpriteNode else { return }
//        let bounce = SKAction.sequence([
//            SKAction.moveBy(x: 0, y: 10, duration: 0.5),
//            SKAction.moveBy(x: 0, y: -10, duration: 0.5)
//        ])
//        spriteNode.run(SKAction.repeatForever(bounce))
//    }
    
//     MARK: Physics
    public override func didSimulatePhysics() {
        if !viruses.isEmpty && isMoving {
            updateViruses()
            updateWhiteCell()
        }
    }
    
    // MARK: Colision
    public func didBegin(_ contact: SKPhysicsContact) {
        if levelCompleted {
            return
        }
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        // Contact
        let a = Int(bodyA.categoryBitMask)
        let b = Int(bodyB.categoryBitMask)
        
        if contactIsBetween(a, b, are: [DEFENSECELL, VIRUS]) {
            // if is last virus, then end phase
            // if is not last virus, then continue phase
            print("White cell and virus")
        } else if contactIsBetween(a, b, are: [DEFENSECELL, REDCELL]) {
            print("White cell and red cell")
        }
        // Other colisions are irrelevant
    }
    
    private func contactIsBetween(_ bodyA: Int, _ bodyB: Int, are bodies: [Int]) -> Bool {
        return [bodyA, bodyB] == bodies || [bodyB, bodyA] == bodies
    }
    
    // MARK: Level completion
    private func levelCompletion(won: Bool) {
        let transition = SKTransition.moveIn(with: .right, duration: 0.5)
        if won {
            guard let nextSKSCene = nextSKSCene else {
                return
            }
            nextSKSCene.scaleMode = .aspectFit
            view?.presentScene(nextSKSCene, transition: transition)
        } else {
            guard let repeatScene = repeatScene else {
                return
            }
            repeatScene.scaleMode = .aspectFit
            view?.presentScene(repeatScene, transition: transition)
        }
    }
    
    // MARK: Touches handler
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchHandler(touches)
    }
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchHandler(touches)
    }
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchHandler(touches)
    }
    private func touchHandler(_ touches: Set<UITouch>) {
        isMoving = true
        lastTouch = touches.first?.location(in: self)
        
        if canMove {
            canMove = false
            touchTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
                self.canMove = true
            }
            updateWhiteCell()
        }
    }
    
}
