import SpriteKit
import GameplayKit

public class Level: SKScene, SKPhysicsContactDelegate {
    
    // MARK: Outlets
    var whiteCell: SKSpriteNode?
    var viruses: [SKSpriteNode] = []
    var badFeedback: SKSpriteNode?
    
    // MARK: Bitmask IDs
    let DEFENSECELL = 1
    let HELPERBCELL = 2
    let VIRUS = 4
    let REDCELL = 8
    let ANTIBODY = 16
    let WALL = 32
    
    // MARK: Defense cell variables
    let whiteCellName = "whiteCell"
    var whiteCellSpeed: CGFloat = 160
    
    // MARK: Viruses variables
    let virusName = "virus"
    let bossVirusName = "boss_virus"
    let virusSpeed: CGFloat = 240
    
    // MARK: Red Cell variables
    let redCellName = "redCell"
    let redCellSpeed: CGFloat = 200
    
    // MARK: Level variables
    var lastTouch: CGPoint? = nil
    var updates: Int = 0
    var touchTimer: Timer?
    var canMove: Bool = true
    var isMoving: Bool = false
    
    var virusesThatPassed: Int = 0
    var eatenRedCells: Int = 0
    var levelCompleted: Bool = false
    
    // MARK: Level computed variable
    var level: Int { 0 }
    var virusesTolerance: Int { 0 }
    var redCellTolerance: Int { 0 }
    // to know how much of a delay is necessary between node animations
    var virusDelayTime: CGFloat { 0 }
    var redCellDelayTime: CGFloat { 0 }
    var shouldCareForRedCellContact: Bool { false }
    // to know how much delay between taps
    var touchCooldownPeriod: CGFloat { 0.1 }
    
    public override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        setNodes()
    }
    
    private func setNodes() {
        // Regular nodes configuration
        whiteCell = childNode(withName: whiteCellName) as? SKSpriteNode
        badFeedback = childNode(withName: "bad_feedback") as? SKSpriteNode
        // Virus movement configuration
        var delayTime: CGFloat = 0
        for child in self.children where child.name == virusName {
            if let virus = child as? SKSpriteNode {
                viruses.append(virus)
                virus.run(.move(by: .zero, duration: delayTime), completion: {
                    self.vectorialMovement(virus, to: CGPoint(x: -700, y: virus.position.y), speed: self.virusSpeed)
                })
                delayTime += virusDelayTime
            }
        }
        delayTime = .zero
        // Red Cell movement configuration
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
    
    // MARK: Colision
    public func didBegin(_ contact: SKPhysicsContact) {
        if levelCompleted {
            return
        }
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        let a = Int(bodyA.categoryBitMask)
        let b = Int(bodyB.categoryBitMask)
        
        if contactIsBetween(a, b, are: [DEFENSECELL, VIRUS]) {
            whiteCellSpeed += 20
            if viruses.isEmpty { // In case is touching a dying bacteria
                return
            }
            removeNode(a == VIRUS ? bodyA : bodyB, isVirus: true)
            print("{CONTACT}\t[DEFENSECELL VIRUS]\t\t<code block>\tcompletion")
        } else if shouldCareForRedCellContact, contactIsBetween(a, b, are: [DEFENSECELL, REDCELL]) {
            removeNode(a == REDCELL ? bodyA : bodyB)
            eatenRedCells += 1
            if redCellTolerance == 0 || redCellTolerance - eatenRedCells < 0 {
                self.levelCompleted = true
                self.levelCompletion(won: false)
            }
            badFeedbackAction()
            print("{CONTACT}\t[DEFENSECELL REDCELL]\t<code block>\tcompletion")
        } else if contactIsBetween(a, b, are: [VIRUS, WALL]) {
            // Can loose game
            removeNode(a == VIRUS ? bodyA : bodyB, isVirus: true)
            virusesThatPassed += 1
            if virusesTolerance == 0 || virusesTolerance - virusesThatPassed < 0 {
                self.levelCompleted = true
                self.levelCompletion(won: false)
            }
            badFeedbackAction()
            print("{CONTACT}\t[VIRUS WALL]\t\t\t<code block>\tcompletion")
        }
        // Other colisions are irrelevant
    }
    
    private func badFeedbackAction() {
        guard let feedbackAction = SKAction.init(named: "Feedback_Bad"),
              let feedbackNode = badFeedback else { return }
        feedbackNode.run(feedbackAction)
    }
    
    func removeNode(_ body: SKPhysicsBody, isVirus: Bool = false) {
        guard let node = body.node as? SKSpriteNode else { return }
        // Remove node from physics scene and its game reference
        node.physicsBody?.categoryBitMask = 0
        node.run(SKAction.init(named: "Virus_Death")!, completion: {
            node.removeFromParent()
        })
        if isVirus, let index = viruses.firstIndex(of: node) {
            viruses.remove(at: index)
            // If is the last virus, then end phase
            if viruses.isEmpty {
                self.levelCompleted = true
                self.levelCompletion(won: true)
            }
            // Animate virus death and remove it from the scene
        }
    }
    
    public func contactIsBetween(_ bodyA: Int, _ bodyB: Int, are bodies: [Int]) -> Bool {
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
            touchTimer = Timer.scheduledTimer(withTimeInterval: touchCooldownPeriod, repeats: false) { [weak self] timer in
                self?.canMove = true
            }
            touchAction()
        }
    }
    @objc public func touchAction() {
        updateWhiteCell()
    }
}

struct VirusTuple {
    typealias AntiBodies = Int
    
    let virus: SKSpriteNode
    let totalNodesAttacking: AntiBodies
}

public class FinalLevel: Level {
    // MARK: Defense cell variables
    private let helperBCellName = "helperBCell"
    // MARK: Viruses
    var bossViruses: Array<SKSpriteNode> = []
    var targetViruses: Array<VirusTuple> = []
    
    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        targetViruses = viruses.map{ VirusTuple(virus: $0, totalNodesAttacking: 0) }
        whiteCell = childNode(withName: helperBCellName) as? SKSpriteNode
        for node in self.children where node.name == "boss_virus" {
            if let boss = node as? SKSpriteNode {
                bossViruses.append(boss)
                targetViruses.append(VirusTuple(virus: boss, totalNodesAttacking: 0))
                // codar tempo ocioso
                // codar tempo de ativação
            }
        }
    }
    
    @objc override public func touchAction() {
        guard
            let antibodyNode = SKReferenceNode(fileNamed: "Reference_Antibody"),
            let virusNode = getClosestUntargetedVirus(),
            let whiteCell = whiteCell
        else {
            return
        }
        antibodyNode.position = CGPoint(
            x: whiteCell.position.x + whiteCell.size.width * 0.6,
            y: 0)
        antibodyNode.run(.init(named: "Antibody")!)
        antibodyNode.run(.move(to: virusNode.position, duration: 0.5))
        
        scene?.addChild(antibodyNode)
    }
    
    // Most left node (lower X value)
    private func getClosestUntargetedVirus() -> SKSpriteNode? {
        var selectedVirus: SKSpriteNode? = nil
        for virusTuple in targetViruses where (virusTuple.virus.name ?? "").contains(virusName) {
            if selectedVirus == nil {
                selectedVirus = virusTuple.virus
            }
            
            
//            if selectedVirus == nil {
//                selectedVirus = virusTuple.a
//            } else if selectedVirus!.position.x < virusTuple.a.position.x {
//                selectedVirus = virusTuple.a
//            }
        }
        return selectedVirus
    }
    
    // Returns skspritenode if virus can be targeted, otherwise returns nil
    private func isAvailable(_ tuple: VirusTuple) -> SKSpriteNode? {
        if let name = tuple.virus.name {
            if name == virusName && tuple.totalNodesAttacking == 0 {
                // regular virus
                return tuple.virus
            } else if name == bossVirusName && tuple.totalNodesAttacking <= 1 {
                // boss virus
                return tuple.virus
            }
        }
        return nil
    }
    
    public override func didBegin(_ contact: SKPhysicsContact) {
        super.didBegin(contact)
        if levelCompleted {
            return
        }
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        let a = Int(bodyA.categoryBitMask)
        let b = Int(bodyB.categoryBitMask)
        
        if contactIsBetween(a, b, are: [ANTIBODY, VIRUS]) {
            removeNode(bodyA)
            removeNode(bodyB)
            print("{CONTACT}\t[ANTIBODY VIRUS]\t\t<code block>\tcompletion")
        }
    }
}
