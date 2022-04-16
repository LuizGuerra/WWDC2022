import SpriteKit
import GameplayKit

public class Level: SKScene, SKPhysicsContactDelegate {
    
    // MARK: Outlets
    var whiteCell: SKSpriteNode?
    var viruses: [SKSpriteNode] = []
    
    // MARK: Bitmask IDs
    private let DEFENSECELL = 1
    private let VIRUS = 2
    private let REDCELL = 3
    private let WALL = 4
    
    // MARK: Defense cell variables
    private let whiteCellName = "whiteCell"
    private var whiteCellSpeed: CGFloat = 160
    
    // MARK: Viruses variables
    private let virusName = "virus"
    private let virusSpeed: CGFloat = 100
    
    // MARK: Level variables
    var lastTouch: CGPoint? = nil
    var updates: Int = 0
    var touchTimer: Timer?
    
    var canMove: Bool = true
    var isMoving: Bool = false
    
    var levelCompleted: Bool = false
    
    // MARK: Level computed variable
    var level: Int { 0 }
    
    public override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        setNodes()
    }
    
    private func setNodes() {
        whiteCell = childNode(withName: whiteCellName) as? SKSpriteNode
        for child in self.children where child.name == virusName {
            if let virus = child as? SKSpriteNode {
                viruses.append(virus)
                let originalY = virus.position.y
//                let dy = virus.position.x < 0 ? y
//                virus.run(.move(by: CGVector(dx: -240, dy: dy), duration: 1))
            }
        }
    }
    
    private func virusVector(from original: CGPoint) -> Array<CGFloat> {
        let wasAbove = original.y > 0
        let wasLeft = original.x < 0
        var ys: Array<CGFloat> = []
        var lastY = 0
        for i in 1 ... 6 {
            let a = 0 * 1000
            let b = original.y/2
        }
        
        return ys
    }
    
    func updateWhiteCell() {
        guard let whiteCell = whiteCell, let touch = lastTouch else {
            return
        }
        whiteCell.physicsBody?.isResting = true
        whiteCell.physicsBody?.velocity = .zero
        if canMove(from: whiteCell.position, to: touch) {
            vectorialMovement(whiteCell, to: touch, speed: whiteCellSpeed, rotate: true)
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
    
    private func canMove(from: CGPoint, to: CGPoint) -> Bool {
        guard let whiteCellFrame = whiteCell?.frame else {
            return false
        }
        let insideAllowedWidth = abs(from.x - to.x) > whiteCellFrame.width / 2
        let insideAllowedHeight = abs(from.y - to.y) > whiteCellFrame.height / 2
        return insideAllowedHeight || insideAllowedWidth
    }
    
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
            whiteCellSpeed += 20
            if viruses.isEmpty { // In case is touching a dying bacteria
                return
            }
            print("{CONTACT}\t[DEFENSECELL VIRUS]\t<code block>\tstart")
            if a == VIRUS {
                removeVirus(bodyA)
            } else {
                removeVirus(bodyB)
            }
            print("{CONTACT}\t[DEFENSECELL VIRUS]\t<code block>\tcompletion")
        } else if contactIsBetween(a, b, are: [DEFENSECELL, REDCELL]) {
            print("{CONTACT}\t[DEFENSECELL REDCELL]\t<code block>\tstart")
            print("{CONTACT}\t[DEFENSECELL REDCELL]\t<code block>\tcompletion")
        } else if contactIsBetween(a, b, are: [VIRUS, WALL]) {
            // Can loose game
            print("{CONTACT}\t[VIRUS WALL]\t\t<code block>\tstart")
            self.levelCompleted = true
            self.levelCompletion(won: false)
            print("{CONTACT}\t[VIRUS WALL]\t\t<code block>\tcompletion")
        }
        // Other colisions are irrelevant
    }
    
    private func removeVirus(_ body: SKPhysicsBody) {
        guard let virusNode = body.node as? SKSpriteNode,
              let index = viruses.firstIndex(of: virusNode) else { return }
        body.node?.physicsBody?.categoryBitMask = 0
        viruses.remove(at: index)
        virusNode.run(SKAction.init(named: "Virus_Death")!, completion: {
            virusNode.removeFromParent()
            // if is the last virus, then end phase
            if self.viruses.isEmpty {
                self.levelCompleted = true
                self.levelCompletion(won: true)
            }
        })
    }
    
    private func contactIsBetween(_ bodyA: Int, _ bodyB: Int, are bodies: [Int]) -> Bool {
        return [bodyA, bodyB] == bodies || [bodyB, bodyA] == bodies
    }
    
    // MARK: Level completion
    private func levelCompletion(won: Bool) {
        let fileName = "SpecialScene_Level\(won ? "Passed" : "Failed")"
        guard let nextScene = LevelEndConfigurations(fileNamed: fileName) else { return }
        nextScene.configure(won: won, from: level)
        let moveRight = SKTransition.moveIn(with: .right, duration: 0.5)
        nextScene.scaleMode = .aspectFit
        view?.presentScene(nextScene, transition: moveRight)
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
            touchTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] timer in
                self?.canMove = true
            }
            updateWhiteCell()
        }
    }
    
}
