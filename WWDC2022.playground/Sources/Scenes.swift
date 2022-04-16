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
//    override var nextSKSCene: SKScene? {
//        NeutrophilScene(fileNamed: "05_Neutrophil")
//    }
}

public final class NeutrophilScene: NodeConfigurations {
    override var nextSKScene: SKScene? {
        LevelTwoScene(fileNamed: "06_Level02")
    }
}

public final class LevelTwoScene: Level {
    override var level: Int { 2 }
//    override var nextSKScene: SKScene? {
//        DentriticScene(fileNamed: "07_Dentritic")
//    }
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
//    override var nextSKScene: SKScene? {
//        HelperBScene(fileNamed: "10_HelperB")
//    }
}

public final class HelperBScene: NodeConfigurations {
    override var nextSKScene: SKScene? {
        LevelFourScene(fileNamed: "11_Level04")
    }
}

public final class LevelFourScene: Level {
    override var level: Int { 4 }
//    override var nextSKScene: SKScene? {
//        GameCompleted(fileNamed: "12_End")
//    }
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
