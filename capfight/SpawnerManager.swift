import SpriteKit

// MARK: - SpawnerManager
/// Manager responsible for spawning and maintaining active lists of obstacles, enemies, and items
final class SpawnerManager {
    
    // MARK: - Template & Active Entities
    private(set) var snakeTemplate: SKSpriteNode?
    private(set) var rockTemplate: SKSpriteNode?
    private(set) var capyHelpTemplate: SKSpriteNode?
    private(set) var crocodileTemplate: SKSpriteNode?
    
    var activeSnakes: [SKSpriteNode] = []
    var activeRocks: [SKSpriteNode] = []
    var activeCapyHelps: [SKSpriteNode] = []
    var activeCrocodiles: [SKSpriteNode] = []
    
    private(set) var snakeAnimation: SKAction!
    
    // MARK: - Setup
    func setupTemplates(in scene: SKScene, getScore: @escaping () -> Int = { 0 }) {
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
            startRockSpawner(in: scene, getScore: getScore)
        }
        
        if let helpNode = scene.childNode(withName: "//capy_help") as? SKSpriteNode {
            capyHelpTemplate = helpNode
            capyHelpTemplate?.removeFromParent()
            startCapyHelpSpawner(in: scene)
        }
        
        if let crocNode = scene.childNode(withName: "//crocodile") as? SKSpriteNode {
            crocodileTemplate = crocNode
            crocodileTemplate?.removeFromParent()
            startCrocodileSpawner(in: scene)
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
        newSnake.zPosition = 10
        let spawnY = CGFloat.random(in: -scene.size.height / 2 + 180 ... -40.0)
        newSnake.position = CGPoint(x: scene.size.width / 2 + 150, y: spawnY)
        newSnake.run(snakeAnimation)
        scene.addChild(newSnake)
        activeSnakes.append(newSnake)
    }
    
    private func startCrocodileSpawner(in scene: SKScene) {
        let waitAction = SKAction.wait(forDuration: 6.0, withRange: 2.0)
        let spawnAction = SKAction.run { [weak self, weak scene] in
            guard let scene = scene else { return }
            self?.spawnSingleCrocodile(in: scene)
        }
        scene.run(SKAction.repeatForever(SKAction.sequence([waitAction, spawnAction])))
    }
    
    private func spawnSingleCrocodile(in scene: SKScene) {
        guard let template = crocodileTemplate, let newCroc = template.copy() as? SKSpriteNode else { return }
        newCroc.isHidden = false
        newCroc.zPosition = 8
        newCroc.texture = SKTexture(imageNamed: "crocodile/crocodile_1")
        let minY = -scene.size.height / 2 + 180
        let maxY = -40.0
        newCroc.position = CGPoint(x: scene.size.width / 2 + 200, y: CGFloat.random(in: minY...maxY))
        scene.addChild(newCroc)
        activeCrocodiles.append(newCroc)
    }
    
    private func startRockSpawner(in scene: SKScene, getScore: @escaping () -> Int) {
        let waitAction = SKAction.wait(forDuration: 3.5, withRange: 1.0)
        let spawnAction = SKAction.run { [weak self, weak scene] in
            guard let scene = scene else { return }
            let score = getScore()
            self?.spawnRocks(in: scene, score: score)
        }
        scene.run(SKAction.repeatForever(SKAction.sequence([waitAction, spawnAction])))
    }
    
    private func spawnRocks(in scene: SKScene, score: Int) {
        guard let template = rockTemplate else { return }
        
        // Tentukan jumlah batu berdasarkan skor
        let rockCount: Int
        let randomVal = Double.random(in: 0.0...1.0)
        if score < 100 {
            rockCount = 1
        } else if score < 250 {
            rockCount = randomVal < 0.40 ? 2 : 1 // 40% peluang 2 batu saat skor 100-250
        } else {
            rockCount = randomVal < 0.70 ? 2 : 1 // 70% peluang 2 batu saat skor > 250
        }
        
        let minY = -scene.size.height / 2 + 180
        let maxY = -40.0
        let spawnX = scene.size.width / 2 + 150
        
        if rockCount == 1 {
            guard let newRock = template.copy() as? SKSpriteNode else { return }
            newRock.isHidden = false
            newRock.zPosition = 8
            newRock.position = CGPoint(x: spawnX, y: CGFloat.random(in: minY...maxY))
            scene.addChild(newRock)
            activeRocks.append(newRock)
        } else {
            // Spawn 2 batu di posisi Y & X yang berbeda agar pemain punya celah untuk lewat/melompat
            let midY = (minY + maxY) / 2.0
            
            // Batu 1: Jalur Atas / Tengah
            if let rock1 = template.copy() as? SKSpriteNode {
                rock1.isHidden = false
                rock1.zPosition = 8
                let spawnY1 = CGFloat.random(in: midY + 10 ... maxY)
                rock1.position = CGPoint(x: spawnX, y: spawnY1)
                scene.addChild(rock1)
                activeRocks.append(rock1)
            }
            
            // Batu 2: Jalur Bawah / Tergeser ke kanan sedikit (agar variatif)
            if let rock2 = template.copy() as? SKSpriteNode {
                rock2.isHidden = false
                rock2.zPosition = 8
                let spawnY2 = CGFloat.random(in: minY ... midY - 10)
                let offsetX2 = CGFloat.random(in: 0...100) // Variasi X sedikit agar tidak berjejer kaku
                rock2.position = CGPoint(x: spawnX + offsetX2, y: spawnY2)
                scene.addChild(rock2)
                activeRocks.append(rock2)
            }
        }
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
        newHelp.zPosition = 8
        let spawnY = CGFloat.random(in: -scene.size.height / 2 + 180 ... -40.0)
        newHelp.position = CGPoint(x: scene.size.width / 2 + 150, y: spawnY)
        
        let lilipadTextures = [
            SKTexture(imageNamed: "capybara_lilipad/capybara_lilipad_1"),
            SKTexture(imageNamed: "capybara_lilipad/capybara_lilipad_2"),
            SKTexture(imageNamed: "capybara_lilipad/capybara_lilipad_3")
        ]
        let lilipadAnim = SKAction.repeatForever(SKAction.animate(with: lilipadTextures, timePerFrame: 0.2))
        newHelp.run(lilipadAnim)
        
        scene.addChild(newHelp)
        activeCapyHelps.append(newHelp)
    }
    
    // MARK: - Off-Screen Cleanup Update
    func updateSpawns(leftOffScreen: CGFloat, obstacleSpeed: CGFloat) {
        for (index, croc) in activeCrocodiles.enumerated().reversed() {
            croc.position.x -= obstacleSpeed
            if croc.position.x < leftOffScreen {
                croc.removeFromParent()
                activeCrocodiles.remove(at: index)
            }
        }
        
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
        activeCrocodiles.forEach { $0.removeFromParent() }
        activeSnakes.removeAll()
        activeRocks.removeAll()
        activeCapyHelps.removeAll()
        activeCrocodiles.removeAll()
    }
}
