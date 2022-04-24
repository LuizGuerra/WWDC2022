import SpriteKit
import GameplayKit

public class Level: SKScene, SKPhysicsContactDelegate {
    
    // MARK: Outlets
    var whiteCell: SKSpriteNode?
    var bacteriaList: [SKSpriteNode] = []
    var badFeedback: SKSpriteNode?
    
    // MARK: Bitmask IDs
    let DEFENSECELL = 1
    let HELPERBCELL = 2
    let BACTERIUM = 4
    let REDCELL = 8
    let ANTIBODY = 16
    let WALL = 32
    
    // MARK: Defense cell variables
    let whiteCellName = "whiteCell"
    var whiteCellSpeed: CGFloat = 160
    
    // MARK: Bacterium variables
    let bacteriumName = "bacteria"
    let bossBacteriumName = "boss_bacteria"
    let bacteriumSpeed: CGFloat = 240
    
    // MARK: Red Cell variables
    let redCellName = "redCell"
    let redCellSpeed: CGFloat = 200
    
    // MARK: Red Cell variables
    let antibodyName = "antibody"
    let antibodySpeed: CGFloat = 500
    
    // MARK: Level variables
    var lastTouch: CGPoint? = nil
    var updates: Int = 0
    var touchTimer: Timer?
    var canMove: Bool = true
    var isMoving: Bool = false
    
    var bacteriaThatPassed: Int = 0
    var eatenRedCells: Int = 0
    var levelCompleted: Bool = false
    
    var touchCooldownBonus: CGFloat = 0
    
    // MARK: Level computed variable
    var level: Int { 0 }
    var bacteriumTolerance: Int { 0 }
    var redCellTolerance: Int { 0 }
    // to know how much of a delay is necessary between node animations
    var bacteriumDelayTime: CGFloat { 0 }
    var redCellDelayTime: CGFloat { 0 }
    var shouldCareForRedCellContact: Bool { false }
    // to know how much delay between taps
    var touchCooldownPeriod: CGFloat { 0.1 }
    
    public override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        // Regular nodes configuration
        whiteCell = childNode(withName: whiteCellName) as? SKSpriteNode
        badFeedback = childNode(withName: "bad_feedback") as? SKSpriteNode
        setBacterium()
        setRedCells()
    }
    
    func setBacterium() {
        var delayTime: CGFloat = 0
        for child in self.children where child.name == bacteriumName {
            if let bacterium = child as? SKSpriteNode {
                bacteriaList.append(bacterium)
                bacterium.run(.move(by: .zero, duration: delayTime), completion: {
                    self.vectorialMovement(bacterium, to: CGPoint(x: -10000, y: bacterium.position.y), speed: self.bacteriumSpeed)
                })
                delayTime += bacteriumDelayTime
            }
        }
    }
    
    func setRedCells() {
        var delayTime: CGFloat = 0
        for child in self.children where child.name == redCellName {
            if let redCell = child as? SKSpriteNode {
                redCell.run(.move(by: .zero, duration: delayTime), completion: {
                    self.vectorialMovement(redCell, to: CGPoint(x: -10000, y: redCell.position.y), speed: self.redCellSpeed)
                })
                delayTime += redCellDelayTime
            }
        }
    }
    
    // MARK: Interactive node movements
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
    
    private func canMove(from: CGPoint, to: CGPoint) -> Bool {
        guard let whiteCellFrame = whiteCell?.frame else {
            return false
        }
        let insideAllowedWidth = abs(from.x - to.x) > whiteCellFrame.width / 2
        let insideAllowedHeight = abs(from.y - to.y) > whiteCellFrame.height / 2
        return insideAllowedHeight || insideAllowedWidth
    }
    
    final func vectorialMovement(_ sprite: SKNode, to: CGPoint, speed: CGFloat, rotate: Bool = false) {
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
    
    final func bacteriumAttack() {
        bacteriaThatPassed += 1
        if bacteriumTolerance == 0 || bacteriumTolerance - bacteriaThatPassed < 0 {
            levelCompleted = true
            levelCompletion(won: false)
        }
    }
    
    // MARK: Colision
    public func didBegin(_ contact: SKPhysicsContact) {
        if levelCompleted {
            return
        }
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        let a = Int(bodyA.categoryBitMask)
        let b = Int(bodyB.categoryBitMask)
        
        if contactIsBetween(a, b, are: [DEFENSECELL, BACTERIUM]) {
            whiteCellSpeed += 20
            if bacteriaList.isEmpty { // In case is touching a dying bacteria
                return
            }
            removeNode(a == BACTERIUM ? bodyA : bodyB, isBacterium: true)
        } else if shouldCareForRedCellContact, contactIsBetween(a, b, are: [DEFENSECELL, REDCELL]) {
            removeNode(a == REDCELL ? bodyA : bodyB)
            eatenRedCells += 1
            if redCellTolerance == 0 || redCellTolerance - eatenRedCells < 0 {
                self.levelCompleted = true
                self.levelCompletion(won: false)
            }
            badFeedbackAction()
        } else if contactIsBetween(a, b, are: [BACTERIUM, WALL]) {
            // Can loose game
            removeNode(a == BACTERIUM ? bodyA : bodyB, isBacterium: true)
            bacteriumAttack()
            badFeedbackAction()
        }
        // Other colisions are irrelevant
    }
    
    final func badFeedbackAction() {
        guard let feedbackAction = SKAction.init(named: "Feedback_Bad"),
              let feedbackNode = badFeedback else { return }
        feedbackNode.run(feedbackAction)
    }
    
    @objc func removeNode(_ body: SKPhysicsBody, isBacterium: Bool = false) {
        guard let node = body.node as? SKSpriteNode else { return }

        // Remove node from physics scene and its game reference
        if node.name == "antibody" { // because is a reference node
            body.categoryBitMask = 0
            node.parent?.parent?.removeAllActions()
            node.parent?.parent?.run(.fadeOut(withDuration: 0.5), completion: {
                node.removeFromParent()
            })
            return
        }
        node.physicsBody?.categoryBitMask = 0
        node.run(.fadeOut(withDuration: 1), completion: {
            node.removeFromParent()
        })
        if isBacterium, let index = bacteriaList.firstIndex(of: node) {
            bacteriaList.remove(at: index)
            // If is the last bacterium, then end phase
            if bacteriaList.isEmpty {
                self.levelCompleted = true
                self.levelCompletion(won: true)
            }
        }
    }
    
    public func contactIsBetween(_ bodyA: Int, _ bodyB: Int, are bodies: [Int]) -> Bool {
        return [bodyA, bodyB] == bodies || [bodyB, bodyA] == bodies
    }
    
    // MARK: Level completion
    final func levelCompletion(won: Bool) {
        let fileName = "SpecialScene_Level\(won ? "Passed" : "Failed")"
        guard let nextScene = LevelEndConfigurations(fileNamed: fileName) else { return }
        nextScene.configure(won: won, from: level)
        let moveRight = SKTransition.moveIn(with: .right, duration: 0.5)
        nextScene.scaleMode = .aspectFit
        view?.presentScene(nextScene, transition: moveRight)
    }
    
}

struct BacteriumTuple {
    typealias AntiBodies = Int
    
    let bacterium: SKSpriteNode
    var totalNodesAttacking: AntiBodies
    
    func maxNodesAttacking() -> Int {
        if let name = bacterium.name {
            return name == "bacteria" ? 1 : 3
        }
        return 1
    }
}

public class FinalLevel: Level {
    // MARK: Defense cell variables
    private let helperBCellName = "helperBCell"
    // MARK: Bacterium
    var targetBacteria: [BacteriumTuple] = []
    var bossDelayTime = 2
    
    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        whiteCell = childNode(withName: helperBCellName) as? SKSpriteNode
        targetBacteria = bacteriaList.map{ BacteriumTuple(bacterium: $0, totalNodesAttacking: 0) }
    }
    
    override func setBacterium() {
        // throw enemies in 4 different waves
        var waveIndex = 0
        let wavesCount = [3, 5, 6, 3]
        var aux = 0
        // Configure SKActions in waves
        var delayTime = CGFloat.zero
        // for each bacterium and boss bacterium
        for node in self.children where (node.name ?? "").contains(bacteriumName) {
            // update if necessary wave index
            if aux == 0 {
                waveIndex += 1
                aux = wavesCount[waveIndex-1]
                delayTime += 0.5
            }
            if let bacteriumNode = node as? SKSpriteNode {
                bacteriaList.append(bacteriumNode)
                targetBacteria.append(.init(bacterium: bacteriumNode, totalNodesAttacking: 0))
                bacteriumNode.run(.wait(forDuration: delayTime), completion: {
                    let destiny = CGPoint(x: -800, y: bacteriumNode.position.y)
                    self.vectorialMovement(bacteriumNode, to: destiny, speed: self.bacteriumSpeed)
                })
                delayTime += bacteriumDelayTime
            }
            aux -= 1
        }
    }
    
    // Most left node (lower X value)
    private func getClosestUntargetedBacterium() -> SKSpriteNode? {
        var selectedBacterium: SKSpriteNode? = nil
        for bacteriumTuple in targetBacteria where (bacteriumTuple.bacterium.name ?? "").contains(bacteriumName) {
            // if selectedBacterium variable was already setted
            if let selectedPosition = selectedBacterium?.position {
                if let bacterium = isBacteriumAvailable(bacteriumTuple), selectedPosition.x > bacterium.position.x {
                    selectedBacterium = bacterium
                }
            } else {
                // if selectedBacterium variable is null
                selectedBacterium = bacteriumTuple.bacterium
            }
        }
        return selectedBacterium
    }
        
    // Returns skspritenode if bacterium can be targeted, otherwise returns nil
    private func isBacteriumAvailable(_ tuple: BacteriumTuple) -> SKSpriteNode? {
        if let name = tuple.bacterium.name {
            if name == bacteriumName && tuple.totalNodesAttacking == 0 {
                // regular bacterium
                return tuple.bacterium
            } else if name == bossBacteriumName && tuple.totalNodesAttacking <= 1 {
                // boss bacterium
                return tuple.bacterium
            }
        }
        return nil
    }
    // MARK: Physics Contact
    public override func didBegin(_ contact: SKPhysicsContact) {
        super.didBegin(contact)
        if levelCompleted {
            return
        }
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        let a = Int(bodyA.categoryBitMask)
        let b = Int(bodyB.categoryBitMask)
        
        if contactIsBetween(a, b, are: [ANTIBODY, BACTERIUM]) {
            let bacteriumBody = a == BACTERIUM ? bodyA : bodyB
            let antibodyBody = a == ANTIBODY ? bodyA : bodyB
            if let bacteriumNode = bacteriumBody.node,
               let index = targetBacteria.firstIndex(where: { $0.bacterium == bacteriumNode }) {
                targetBacteria[index].totalNodesAttacking += 1
                if bacteriumNode.name == bossBacteriumName && targetBacteria[index].totalNodesAttacking > 2 {
                    // if boss finally can die
                    removeNode(bacteriumBody)
                } else if bacteriumNode.name == bossBacteriumName {
                    // if didnt die, restitute its velocity
                    let destiny = CGPoint(x: -800, y: bacteriumNode.position.y)
                    self.vectorialMovement(bacteriumNode, to: destiny, speed: self.bacteriumSpeed)
                } else if bacteriumNode.name == bacteriumName {
                    // if is regular bacterium, kill it
                    removeNode(bacteriumBody)
                }
            }
            touchCooldownBonus += 0.025
            removeNode(antibodyBody)
            tryFinishGame(won: true)
        } else if contactIsBetween(a, b, are: [HELPERBCELL, BACTERIUM]) {
            bacteriumAttack()
            badFeedbackAction()
            removeNode(a == BACTERIUM ? bodyA : bodyB, isBacterium: true)
            tryFinishGame(won: false)
        } else if contactIsBetween(a, b, are: [BACTERIUM, WALL]) {
            bacteriumAttack()
            tryFinishGame(won: false)
        }
    }
    func tryFinishGame(won result: Bool) {
        if targetBacteria.isEmpty {
            self.levelCompleted = true
            self.levelCompletion(won: true)
        }
    }
    override func removeNode(_ body: SKPhysicsBody, isBacterium: Bool = false) {
        super.removeNode(body, isBacterium: isBacterium)
        guard let node = body.node else { return }
        if let index = targetBacteria.firstIndex(where: { $0.bacterium == node }) {
            targetBacteria.remove(at: index)
        }
    }
}

// MARK: Touch handler
extension Level {
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
        lastTouch = touches.first?.location(in: self)
        isMoving = true
        if canMove {
            canMove = false
            touchTimer = Timer.scheduledTimer(withTimeInterval: touchCooldownPeriod - touchCooldownBonus, repeats: false) { [weak self] timer in
                self?.canMove = true
            }
            // avoid false setting movement variables
            guard let pos = touches.first?.location(in: self) else { return }
            touchAction(to: pos)
        }
    }
    @objc public func touchAction(to pos: CGPoint) {
        updateWhiteCell()
    }
}

// MARK: Touch handler
extension FinalLevel {
    @objc override public func touchAction(to pos: CGPoint) {
        guard
            let antibodyNode = SKReferenceNode(fileNamed: "Reference_Antibody"),
            let whiteCell = whiteCell
        else {
            return
        }
        // Position antibody in front of helper B cell
        antibodyNode.position = CGPoint(
            x: whiteCell.position.x + whiteCell.size.width * 0.6,
            y: 0)
        scene?.addChild(antibodyNode)
        // Move cell to point destiny
        let angle = CGFloat.pi + atan2(antibodyNode.position.y - pos.y, antibodyNode.position.x - pos.x)
        let velocityVector = CGVector(dx: antibodySpeed * cos(angle), dy: antibodySpeed * sin(angle))
        antibodyNode.children[0].children[0].physicsBody?.velocity = velocityVector
    }
}
