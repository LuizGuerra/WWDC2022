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
    override var nextSKSCene: SKScene? {
        NeutrophilScene(fileNamed: "05_Neutrophil")
    }
}

public final class NeutrophilScene: NodeConfigurations {
    override var nextSKScene: SKScene? {
        HomeScene(fileNamed: "01_Home")
    }
}

