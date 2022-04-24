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
    
    // MARK: Viruses variables
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
//                    virus.run(.move(to: CGPoint(x: -virus.position.x, y: virus.position.y), duration: 10))
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
                    self.vectorialMovement(redCell, to: CGPoint(x: -700, y: redCell.position.y), speed: self.redCellSpeed)
                })
                delayTime += redCellDelayTime
            }
        }
    }
    
    // MARK: Helper functions to find the correct angular velocity formula for each bacteria given their origin point
    private func virusVector(from original: CGPoint) -> Array<CGFloat> {
        let wasAbove = original.y > 0
//        let wasLeft = original.x < 0
        var ys: Array<CGFloat> = []
        // Using the logic of f(x) = ax^2 + bx + c
//        var a = findQuadraticA(from: original.x)
//        var c = findQuadraticC(from: original.y)
        // Keeping count of where in the graph the calculation is
//        var lastX = 600
        // Running through the graph divided in 4 parts of 300
        for i in 1 ... 4 {
            if i <= 2 {
                ys.append(wasAbove ? -20 : +20)
            } else {
                ys.append(wasAbove ? +20 : -20)
            }
        }
        return ys
    }
    private func findQuadraticA(from x: CGFloat) -> CGFloat {
        return (-(x*x)/9)+10_000
    }
    private func findQuadraticC(from y: CGFloat) -> CGFloat {
        return y/2
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
    
    final func vectorialMovement(_ sprite: SKNode, to: CGPoint, speed: CGFloat, rotate: Bool = false, withCompletion: (() -> Void)? = nil) {
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
                withCompletion?()
            })
        } else {
            sprite.removeAllActions()
            sprite.physicsBody?.velocity = velocityVector
        }
    }
    
    final func virusAttack() {
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
            removeNode(a == BACTERIUM ? bodyA : bodyB, isVirus: true)
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
            removeNode(a == BACTERIUM ? bodyA : bodyB, isVirus: true)
            virusAttack()
            badFeedbackAction()
        }
        // Other colisions are irrelevant
    }
    
    final func badFeedbackAction() {
        guard let feedbackAction = SKAction.init(named: "Feedback_Bad"),
              let feedbackNode = badFeedback else { return }
        feedbackNode.run(feedbackAction)
    }
    
    @objc func removeNode(_ body: SKPhysicsBody, isVirus: Bool = false) {
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
        if isVirus, let index = bacteriaList.firstIndex(of: node) {
            bacteriaList.remove(at: index)
            // If is the last virus, then end phase
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

struct VirusTuple {
    typealias AntiBodies = Int
    
    let virus: SKSpriteNode
    var totalNodesAttacking: AntiBodies
    
    func maxNodesAttacking() -> Int {
        if let name = virus.name {
            return name == "virus" ? 1 : 3
        }
        return 1
    }
}

public class FinalLevel: Level {
    // MARK: Defense cell variables
    private let helperBCellName = "helperBCell"
    // MARK: Viruses
    var targetViruses: Array<VirusTuple> = []
    
    var bossDelayTime = 2
    
    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        whiteCell = childNode(withName: helperBCellName) as? SKSpriteNode
        targetViruses = bacteriaList.map{ VirusTuple(virus: $0, totalNodesAttacking: 0) }
        
    }
    
    override func setViruses() {
        // throw enemies in 4 different waves
        var waveIndex = 0
        let wavesCount = [3, 5, 6, 3]
        var aux = 0
        // Configure SKActions in waves
        var delayTime = CGFloat.zero
        // for each virus and boss virus
        for node in self.children where (node.name ?? "").contains(bacteriumName) {
            // update if necessary wave index
            if aux == 0 {
                waveIndex += 1
                aux = wavesCount[waveIndex-1]
                delayTime += 0.5
            }
            if let virusNode = node as? SKSpriteNode {
                bacteriaList.append(virusNode)
                targetViruses.append(.init(virus: virusNode, totalNodesAttacking: 0))
                virusNode.run(.wait(forDuration: delayTime), completion: {
                    let destiny = CGPoint(x: -800, y: virusNode.position.y)
                    self.vectorialMovement(virusNode, to: destiny, speed: self.bacteriumSpeed)
                })
                delayTime += bacteriumDelayTime
            }
            aux -= 1
        }
    }
    
    // Most left node (lower X value)
    private func getClosestUntargetedVirus() -> SKSpriteNode? {
        var selectedVirus: SKSpriteNode? = nil
        for virusTuple in targetViruses where (virusTuple.virus.name ?? "").contains(bacteriumName) {
            // if selectedVirus variable was already setted
            if let selectedPosition = selectedVirus?.position {
                if let virus = isVirusAvailable(virusTuple), selectedPosition.x > virus.position.x {
                    selectedVirus = virus
                }
            } else {
                // if selectedVirus variable is null
                selectedVirus = virusTuple.virus
            }
        }
        return selectedVirus
    }
        
    // Returns skspritenode if virus can be targeted, otherwise returns nil
    private func isVirusAvailable(_ tuple: VirusTuple) -> SKSpriteNode? {
        if let name = tuple.virus.name {
            if name == bacteriumName && tuple.totalNodesAttacking == 0 {
                // regular virus
                return tuple.virus
            } else if name == bossBacteriumName && tuple.totalNodesAttacking <= 1 {
                // boss virus
                return tuple.virus
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
            let virusBody = a == BACTERIUM ? bodyA : bodyB
            let antibodyBody = a == ANTIBODY ? bodyA : bodyB
            if let virusNode = virusBody.node,
               let index = targetViruses.firstIndex(where: { $0.virus == virusNode }) {
                targetViruses[index].totalNodesAttacking += 1
                if virusNode.name == bossBacteriumName {
                    print("Count: ", targetViruses.count, ", index: ", index)
                }
                if virusNode.name == bossBacteriumName && targetViruses[index].totalNodesAttacking > 2 {
                    // if boss finally can die
                    removeNode(virusBody)
                } else if virusNode.name == bossBacteriumName {
                    // if didnt die, restitute its velocity
                    let destiny = CGPoint(x: -800, y: virusNode.position.y)
                    self.vectorialMovement(virusNode, to: destiny, speed: self.bacteriumSpeed)
                } else if virusNode.name == bacteriumName {
                    // if is regular virus, kill it
                    removeNode(virusBody)
                }
            }
            touchCooldownBonus += 0.025
            removeNode(antibodyBody)
            tryFinishGame(won: true)
        } else if contactIsBetween(a, b, are: [HELPERBCELL, BACTERIUM]) {
            virusAttack()
            badFeedbackAction()
            removeNode(a == BACTERIUM ? bodyA : bodyB, isVirus: true)
            tryFinishGame(won: false)
        } else if contactIsBetween(a, b, are: [BACTERIUM, WALL]) {
            virusAttack()
            tryFinishGame(won: false)
        }
    }
    func tryFinishGame(won result: Bool) {
        if targetViruses.isEmpty {
            self.levelCompleted = true
            self.levelCompletion(won: true)
        }
    }
    override func removeNode(_ body: SKPhysicsBody, isVirus: Bool = false) {
        super.removeNode(body, isVirus: isVirus)
        guard let node = body.node else { return }
        if let index = targetViruses.firstIndex(where: { $0.virus == node }) {
            targetViruses.remove(at: index)
        }
    }
}

// MARK: Touch actions
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
