import Foundation
import SpriteKit

public final class HomeScene: NodeConfigurations {
    override var nextSKScene: SKScene? {
        IntroductionScene(fileNamed: "02_Introduction")
    }
}

public final class IntroductionScene: NodeConfigurations {
    override var nextSKScene: SKScene? {
        MacrophageScene(fileNamed: "03_Macrophage")
    }
}

public final class MacrophageScene: NodeConfigurations {
    override var nextSKScene: SKScene? {
        LevelOneScene(fileNamed: "04_Level01")
    }
}

public final class LevelOneScene: Level {
    override var level: Int { 1 }
    override var bacteriumTolerance: Int { 1 }
    override var bacteriumDelayTime: CGFloat { 1.5 }
}

public final class NeutrophilScene: NodeConfigurations {
    override var nextSKScene: SKScene? {
        LevelTwoScene(fileNamed: "06_Level02")
    }
}

public final class LevelTwoScene: Level {
    override var level: Int { 2 }
    override var bacteriumDelayTime: CGFloat { 1.5 }
    override var redCellDelayTime: CGFloat { 3 }
    override var shouldCareForRedCellContact: Bool { true }
    override var redCellTolerance: Int { 1 }
    override var bacteriumTolerance: Int { 1 }
}

public final class DentriticScene: NodeConfigurations {
    override var nextSKScene: SKScene? {
        HelperTScene(fileNamed: "08_HelperT")
    }
}

public final class HelperTScene: NodeConfigurations {
    override var nextSKScene: SKScene? {
        LevelThreeScene(fileNamed: "09_Level03")
    }
}

public final class LevelThreeScene: Level {
    override var level: Int { 3 }
    override var bacteriumDelayTime: CGFloat { 1 }
    override var redCellDelayTime: CGFloat { 4.5 }
    override var shouldCareForRedCellContact: Bool { true }
    override var redCellTolerance: Int { 1 }
    override var bacteriumTolerance: Int { 1 }
}

public final class HelperBScene: NodeConfigurations {
    override var nextSKScene: SKScene? {
        LevelFourScene(fileNamed: "11_Level04")
    }
}

public final class LevelFourScene: FinalLevel {
    override var level: Int { 4 }
    override var bacteriumDelayTime: CGFloat { 0.5 }
    override var bacteriumTolerance: Int { 1 }
    override var touchCooldownPeriod: CGFloat { 0.75 }
}

public final class GameCompleted: NodeConfigurations {
    override var nextSKScene: SKScene? {
        HomeScene(fileNamed: "01_Home")
//        DeveloperInformation()
    }
}

// TODO: this
public final class DeveloperInformation: NodeConfigurations {
    override var nextSKScene: SKScene? {
        nil
    }
}
