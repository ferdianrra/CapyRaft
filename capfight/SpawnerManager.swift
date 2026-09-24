import SpriteKit

// MARK: - SpawnerManager
/// Manager responsible for spawning and maintaining active lists of obstacles, enemies, and items
final class SpawnerManager {
    
    // MARK: - Template & Active Entities
    private(set) var snakeTemplate: SKSpriteNode?
    private(set) var rockTemplate: SKSpriteNode?
    private(set) var capyHelpTemplate: SKSpriteNode?
    
    var activeSnakes: [SKSpriteNode] = []
    var activeRocks: [SKSpriteNode] = []
    var activeCapyHelps: [SKSpriteNode] = []
    
    private(set) var snakeAnimation: SKAction!
    
    // MARK: - Setup
    func setupTemplates(in scene: SKScene) {
        if let snakeNode = scene.childNode(withName: "//snake") as? SKSpriteNode {
            snakeTemplate = snakeNode
            snakeTemplate?.removeFromParent()
            
            let snakeTextures: [SKTexture] = [
                SKTexture(imageNamed: "snake_1"),
                SKTexture(imageNamed: "snake_2"),
                SKTexture(imageNamed: "snake_3"),
                SKTexture(imageNamed: "snake_4"),
                SKTexture(imageNamed: "snake_5")
            ]
            let animateSnake = SKAction.animate(with: snakeTextures, timePerFrame: 0.15)
            snakeAnimation = SKAction.repeatForever(animateSnake)
            
            startSnakeSpawner(in: scene)
        }
        
        var foundRock = scene.childNode(withName: "//rock_obstacle") as? SKSpriteNode
        if foundRock == nil { foundRock = scene.childNode(withName: "//rock") as? SKSpriteNode }
        if foundRock == nil { foundRock = scene.childNode(withName: "//Rock") as? SKSpriteNode }
        
        if let rockNode = foundRock {
            rockTemplate = rockNode
            rockTemplate?.removeFromParent()
            startRockSpawner(in: scene)
        }
        
        if let helpNode = scene.childNode(withName: "//capy_help") as? SKSpriteNode {
            capyHelpTemplate = helpNode
            capyHelpTemplate?.removeFromParent()
            startCapyHelpSpawner(in: scene)
        }
    }
    
    // MARK: - Spawners
    private func startSnakeSpawner(in scene: SKScene) {
        let waitAction = SKAction.wait(forDuration: 2.5, withRange: 1.5)
        let spawnAction = SKAction.run { [weak self, weak scene] in
            guard let scene = scene else { return }
            self?.spawnSingleSnake(in: scene)
        }
        scene.run(SKAction.repeatForever(SKAction.sequence([waitAction, spawnAction])))
    }
    
    private func spawnSingleSnake(in scene: SKScene) {
        guard let template = snakeTemplate, let newSnake = template.copy() as? SKSpriteNode else { return }
        newSnake.isHidden = false
        let spawnY = CGFloat.random(in: -scene.size.height / 2 + 180 ... -40.0)
        newSnake.position = CGPoint(x: scene.size.width / 2 + 150, y: spawnY)
        newSnake.run(snakeAnimation)
        scene.addChild(newSnake)
        activeSnakes.append(newSnake)
    }
    
    private func startRockSpawner(in scene: SKScene) {
        let waitAction = SKAction.wait(forDuration: 3.5, withRange: 1.0)
        let spawnAction = SKAction.run { [weak self, weak scene] in
            guard let scene = scene else { return }
            self?.spawnSingleRock(in: scene)
        }
        scene.run(SKAction.repeatForever(SKAction.sequence([waitAction, spawnAction])))
    }
    
    private func spawnSingleRock(in scene: SKScene) {
        guard let template = rockTemplate, let newRock = template.copy() as? SKSpriteNode else { return }
        newRock.isHidden = false
        let spawnY = CGFloat.random(in: -scene.size.height / 2 + 180 ... -40.0)
        newRock.position = CGPoint(x: scene.size.width / 2 + 150, y: spawnY)
        scene.addChild(newRock)
        activeRocks.append(newRock)
    }
    
    private func startCapyHelpSpawner(in scene: SKScene) {
        let waitAction = SKAction.wait(forDuration: 9.0, withRange: 3.0)
        let spawnAction = SKAction.run { [weak self, weak scene] in
            guard let scene = scene else { return }
            self?.spawnSingleCapyHelp(in: scene)
        }
        scene.run(SKAction.repeatForever(SKAction.sequence([waitAction, spawnAction])))
    }
    
    private func spawnSingleCapyHelp(in scene: SKScene) {
        guard let template = capyHelpTemplate, let newHelp = template.copy() as? SKSpriteNode else { return }
        newHelp.isHidden = false
        let spawnY = CGFloat.random(in: -scene.size.height / 2 + 180 ... -40.0)
        newHelp.position = CGPoint(x: scene.size.width / 2 + 150, y: spawnY)
        scene.addChild(newHelp)
        activeCapyHelps.append(newHelp)
    }
    
    // MARK: - Off-Screen Cleanup Update
    func updateSpawns(leftOffScreen: CGFloat, obstacleSpeed: CGFloat) {
        for (index, rock) in activeRocks.enumerated().reversed() {
            rock.position.x -= obstacleSpeed
            if rock.position.x < leftOffScreen {
                rock.removeFromParent()
                activeRocks.remove(at: index)
            }
        }
        
        for (index, help) in activeCapyHelps.enumerated().reversed() {
            help.position.x -= obstacleSpeed
            if help.position.x < leftOffScreen {
                help.removeFromParent()
                activeCapyHelps.remove(at: index)
            }
        }
    }
    
    func reset() {
        activeSnakes.forEach { $0.removeFromParent() }
        activeRocks.forEach { $0.removeFromParent() }
        activeCapyHelps.forEach { $0.removeFromParent() }
        activeSnakes.removeAll()
        activeRocks.removeAll()
        activeCapyHelps.removeAll()
    }
}
