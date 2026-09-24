import SpriteKit
import UIKit

class GameScene: SKScene {
    
    // MARK: - View Model & Managers
    private let viewModel = GameViewModel()
    private let joystick = JoystickNode()
    private let spawnerManager = SpawnerManager()
    
    // MARK: - Player & Environment Entities
    var capySlots: [SKSpriteNode?] = [nil, nil, nil]
    var slotOffsets: [CGPoint] = [.zero, .zero, .zero]
    
    var wood: SKSpriteNode?
    var playerTemplate: SKSpriteNode?
    var originalWoodScale: CGFloat = 1.0
    var originalCapyScale: CGFloat = 1.0
    
    var bg1: SKSpriteNode?
    var bg2: SKSpriteNode?
    var forest1: SKSpriteNode?
    var forest2: SKSpriteNode?
    
    var activeProjectiles: [SKSpriteNode] = []
    var currentVelocity = CGVector.zero
    
    var throwButton: SKNode!
    var jumpButton: SKNode!
    var scoreLabel: SKLabelNode?
    
    let riverTopMargin: CGFloat = 90.0
    let woodZPosition: CGFloat = 1
    let capyZPosition: CGFloat = 2
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        self.view?.isMultipleTouchEnabled = true
        viewModel.reset()
        
        scoreLabel = self.childNode(withName: "//scoreLabel") as? SKLabelNode
        scoreLabel?.text = "Score: 0"
        
        setupWoodAndPlayers()
        setupBackgrounds()
        
        // Setup Joystick Component
        joystick.setup(sceneSize: size)
        addChild(joystick)
        
        // Setup Spawner Manager Component
        spawnerManager.setupTemplates(in: self)
        
        setupButtons()
    }
    
    private func setupWoodAndPlayers() {
        wood = self.childNode(withName: "//Wood") as? SKSpriteNode
        originalWoodScale = abs(wood?.xScale ?? 1.0)
        wood?.zPosition = woodZPosition
        
        for i in 1...3 {
            if let node = self.childNode(withName: "//MainPlayer\(i)") as? SKSpriteNode {
                capySlots[i-1] = node
                node.zPosition = capyZPosition
                if let w = wood {
                    slotOffsets[i-1] = CGPoint(x: node.position.x - w.position.x, y: node.position.y - w.position.y)
                }
                if i == 1 {
                    playerTemplate = node.copy() as? SKSpriteNode
                    playerTemplate?.zPosition = capyZPosition
                    originalCapyScale = abs(node.xScale)
                }
            }
        }
    }
    
    private func setupBackgrounds() {
        bg1 = self.childNode(withName: "//bg1") as? SKSpriteNode
        bg2 = self.childNode(withName: "//bg2") as? SKSpriteNode
        forest1 = self.childNode(withName: "//forest1") as? SKSpriteNode
        forest2 = self.childNode(withName: "//forest2") as? SKSpriteNode
    }
    
    private func setupButtons() {
        let buttonRadius: CGFloat = 40.0
        
        throwButton = self.childNode(withName: "//throwButton") ?? {
            let node = SKShapeNode(circleOfRadius: buttonRadius)
            node.fillColor = .red
            node.alpha = 0.6
            node.position = CGPoint(x: size.width / 2 - 100, y: -size.height / 2 + 100)
            node.zPosition = 10
            addChild(node)
            return node
        }()
        
        jumpButton = self.childNode(withName: "//jumpButton") ?? {
            let node = SKShapeNode(circleOfRadius: buttonRadius)
            node.fillColor = .blue
            node.alpha = 0.6
            node.position = CGPoint(x: size.width / 2 - 200, y: -size.height / 2 + 150)
            node.zPosition = 10
            addChild(node)
            return node
        }()
    }
    
    // MARK: - Touch Input Handlers
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if joystick.handleTouchBegan(touch, location: location) {
                continue
            }
            if let throwNode = throwButton, throwNode.contains(location) { performThrow() }
            if let jumpNode = jumpButton, jumpNode.contains(location) { performJump() }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            joystick.handleTouchMoved(touch, location: location)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            joystick.handleTouchEnded(touch)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    // MARK: - Actions
    func performThrow() {
        if viewModel.isGameOverTriggered { return }
        guard let w = wood else { return }
        let activeCapys = capySlots.compactMap { $0 }
        if activeCapys.isEmpty { return }
        
        let isFacingRight = w.xScale > 0
        guard let frontCapy = activeCapys.max(by: {
            isFacingRight ? ($0.position.x < $1.position.x) : ($0.position.x > $1.position.x)
        }) else { return }
        
        let throwTextures = [
            SKTexture(imageNamed: "capybara_throw_rock/capybara_throw_rock_1"),
            SKTexture(imageNamed: "capybara_throw_rock/capybara_throw_rock_2"),
            SKTexture(imageNamed: "cap_character")
        ]
        let throwAnim = SKAction.animate(with: throwTextures, timePerFrame: 0.15)
        frontCapy.run(throwAnim)
        
        let rockProjectile = SKSpriteNode(imageNamed: "capybara_throw_rock/rock_throw")
        rockProjectile.setScale(0.15)
        
        let offsetPositionX: CGFloat = isFacingRight ? 50.0 : -50.0
        rockProjectile.position = CGPoint(x: frontCapy.position.x + offsetPositionX, y: frontCapy.position.y)
        rockProjectile.zPosition = 5
        self.addChild(rockProjectile)
        activeProjectiles.append(rockProjectile)
        
        let throwDistanceX: CGFloat = isFacingRight ? 350.0 : -350.0
        let moveRock = SKAction.moveBy(x: throwDistanceX, y: -20.0, duration: 0.4)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        let removeRock = SKAction.removeFromParent()
        
        rockProjectile.run(SKAction.sequence([moveRock, fadeOut, removeRock]))
    }
    
    func performJump() {
        if viewModel.isGameOverTriggered || wood?.action(forKey: "jumping") != nil { return }
        
        let jumpUp = SKAction.moveBy(x: 0, y: 150, duration: 0.3)
        jumpUp.timingMode = .easeOut
        let jumpDown = SKAction.moveBy(x: 0, y: -150, duration: 0.3)
        jumpDown.timingMode = .easeIn
        let jumpSequence = SKAction.sequence([jumpUp, jumpDown])
        
        wood?.run(jumpSequence, withKey: "jumping")
    }
    
    // MARK: - Main Game Loop
    override func update(_ currentTime: TimeInterval) {
        if viewModel.isGameOverTriggered {
            joystick.resetVelocity()
        } else {
            viewModel.updateScore(deltaTime: 1.0 / 60.0) { [weak self] newScore in
                self?.scoreLabel?.text = "Score: \(newScore)"
            }
        }
        
        let leftOffScreen = -size.width - 1000.0
        
        // KONDISI KALAH 1: Semua capybara mati
        if !viewModel.isGameOverTriggered {
            let livingCapys = capySlots.compactMap { $0 }
            let dyingCapys = self.children.filter { $0.name == "dying_capy" }
            if livingCapys.isEmpty && dyingCapys.isEmpty {
                viewModel.triggerGameOver(in: self)
            }
        }
        
        updateBackgrounds()
        spawnerManager.updateSpawns(leftOffScreen: leftOffScreen, obstacleSpeed: viewModel.obstacleSpeed)
        updateWoodAndEntities(leftOffScreen: leftOffScreen)
    }
    
    private func updateBackgrounds() {
        if let b1 = bg1, let b2 = bg2 {
            b1.position.x -= viewModel.riverSpeed
            b2.position.x -= viewModel.riverSpeed
            if b1.position.x <= -b1.size.width { b1.position.x = b2.position.x + b2.size.width }
            if b2.position.x <= -b2.size.width { b2.position.x = b1.position.x + b1.size.width }
        }
        
        if let f1 = forest1, let f2 = forest2 {
            f1.position.x -= viewModel.forestSpeed
            f2.position.x -= viewModel.forestSpeed
            if f1.position.x <= -f1.size.width { f1.position.x = f2.position.x + f2.size.width }
            if f2.position.x <= -f2.size.width { f2.position.x = f1.position.x + f1.size.width }
        }
    }
    
    private func updateWoodAndEntities(leftOffScreen: CGFloat) {
        guard let w = wood else { return }
        
        let isJumping = w.action(forKey: "jumping") != nil
        
        let gerakSpeed: CGFloat = 8.0
        var targetVelocityX = (joystick.velocity.dx * gerakSpeed) + viewModel.woodBackwardSpeed
        let targetVelocityY = joystick.velocity.dy * gerakSpeed
        let friction: CGFloat = 0.15
        
        currentVelocity.dx += (targetVelocityX - currentVelocity.dx) * friction
        currentVelocity.dy += (targetVelocityY - currentVelocity.dy) * friction
        
        w.position.x += currentVelocity.dx
        w.position.y += currentVelocity.dy
        
        var isBlockedByRock = false
        if !isJumping {
            for rock in spawnerManager.activeRocks {
                let combinedHalfWidth = (rock.size.width * rock.xScale + w.size.width) / 2 * 0.45
                let combinedHalfHeight = (rock.size.height * rock.yScale + w.size.height) / 2 * 0.45
                
                let dx = rock.position.x - w.position.x
                let dy = rock.position.y - w.position.y
                
                if abs(dx) < combinedHalfWidth && abs(dy) < combinedHalfHeight {
                    isBlockedByRock = true
                    if dx > 0 { w.position.x = min(w.position.x, rock.position.x - combinedHalfWidth) }
                    else { w.position.x = max(w.position.x, rock.position.x + combinedHalfWidth) }
                }
            }
        }
        
        if isBlockedByRock {
            if currentVelocity.dx > 0 { currentVelocity.dx = 0 }
            targetVelocityX = -viewModel.obstacleSpeed
        }
        
        // Logika pembatas layar
        let marginX: CGFloat = 200.0
        let normalMinX = -size.width / 2 + marginX
        let maxX = size.width / 2 - marginX
        
        if isBlockedByRock { viewModel.isRecovering = true }
        if w.position.x >= normalMinX { viewModel.isRecovering = false }
        
        let appliedMinX = viewModel.isRecovering ? (-size.width - 1000.0) : normalMinX
        
        if joystick.velocity.dx < -0.1 { w.xScale = -originalWoodScale }
        else if joystick.velocity.dx > 0.1 { w.xScale = originalWoodScale }
        
        let isFacingRight = w.xScale > 0
        let minY = (-size.height / 2 + 180) - slotOffsets[0].y
        let maxY = riverTopMargin - slotOffsets[0].y
        
        if !isJumping { w.position.y = max(minY, min(maxY, w.position.y)) }
        else { w.position.y = max(minY, w.position.y) }
        
        w.position.x = max(appliedMinX, min(maxX, w.position.x))
        
        // KONDISI KALAH 2: Kayu hilang di batas kiri
        if !viewModel.isGameOverTriggered {
            let woodRightEdge = w.position.x + (w.size.width / 2)
            if woodRightEdge < -size.width / 2 {
                viewModel.triggerGameOver(in: self)
            }
        }
        
        // Rescue Item Collision
        if !isJumping {
            for (index, help) in spawnerManager.activeCapyHelps.enumerated().reversed() {
                if hypot(w.position.x - help.position.x, w.position.y - help.position.y) < 120.0 {
                    help.removeFromParent()
                    spawnerManager.activeCapyHelps.remove(at: index)
                    
                    for i in 0..<3 {
                        if capySlots[i] == nil {
                            if let newChar = playerTemplate?.copy() as? SKSpriteNode {
                                newChar.zPosition = capyZPosition
                                self.addChild(newChar)
                                capySlots[i] = newChar
                            }
                            break
                        }
                    }
                }
            }
        }
        
        // Sync Capybara Positions
        for i in 0..<3 {
            if let capy = capySlots[i] {
                let offX = isFacingRight ? slotOffsets[i].x : -slotOffsets[i].x
                capy.position = CGPoint(x: w.position.x + offX, y: w.position.y + slotOffsets[i].y)
                capy.xScale = isFacingRight ? originalCapyScale : -originalCapyScale
            }
        }
        
        updateSnakes(isJumping: isJumping, leftOffScreen: leftOffScreen)
        updateProjectiles()
    }
    
    private func updateSnakes(isJumping: Bool, leftOffScreen: CGFloat) {
        for (index, enemy) in spawnerManager.activeSnakes.enumerated().reversed() {
            
            let livingCapyNodes = capySlots.compactMap { $0 }
            guard let chaseTarget = livingCapyNodes.min(by: {
                hypot($0.position.x - enemy.position.x, $0.position.y - enemy.position.y) <
                hypot($1.position.x - enemy.position.x, $1.position.y - enemy.position.y)
            }) else { continue }
            
            let dx = chaseTarget.position.x - enemy.position.x
            let dy = isJumping ? 0 : (chaseTarget.position.y - enemy.position.y)
            let angle = atan2(dy, dx)
            
            enemy.position.x += cos(angle) * viewModel.snakeSpeed
            enemy.position.y += sin(angle) * viewModel.snakeSpeed
            
            let originalEnemyScale = abs(enemy.xScale)
            if dx < -1.0 { enemy.xScale = originalEnemyScale }
            else if dx > 1.0 { enemy.xScale = -originalEnemyScale }
            
            var snakeHit = false
            let hitRadius: CGFloat = 50.0
            
            for i in 0..<3 {
                if let capy = capySlots[i] {
                    let dxHit = capy.position.x - enemy.position.x
                    let dyHit = capy.position.y - enemy.position.y
                    
                    if hypot(dxHit, dyHit) < hitRadius && !isJumping {
                        capySlots[i] = nil
                        capy.name = "dying_capy"
                        capy.removeAllActions()
                        
                        let knockbackX = (dxHit < 0) ? -200.0 : 200.0
                        let knockback = SKAction.moveBy(x: knockbackX, y: 150, duration: 0.4)
                        knockback.timingMode = .easeOut
                        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
                        
                        capy.run(SKAction.sequence([
                            SKAction.group([knockback, fadeOut]),
                            SKAction.removeFromParent()
                        ]))
                        
                        enemy.removeFromParent()
                        spawnerManager.activeSnakes.remove(at: index)
                        snakeHit = true
                        break
                    }
                }
            }
            
            if snakeHit { continue }
            
            if enemy.position.x < leftOffScreen {
                enemy.removeFromParent()
                spawnerManager.activeSnakes.remove(at: index)
            }
        }
    }
    
    private func updateProjectiles() {
        for (projIndex, projectile) in activeProjectiles.enumerated().reversed() {
            if projectile.parent == nil {
                activeProjectiles.remove(at: projIndex)
                continue
            }
            
            var hit = false
            for (snakeIndex, enemy) in spawnerManager.activeSnakes.enumerated().reversed() {
                let dxHit = projectile.position.x - enemy.position.x
                let dyHit = projectile.position.y - enemy.position.y
                
                if hypot(dxHit, dyHit) < 60.0 {
                    hit = true
                    
                    let knockbackX = (dxHit < 0) ? -200.0 : 200.0
                    let knockback = SKAction.moveBy(x: knockbackX, y: 150, duration: 0.3)
                    knockback.timingMode = .easeOut
                    let fadeOut = SKAction.fadeOut(withDuration: 0.3)
                    
                    enemy.removeAllActions()
                    enemy.run(SKAction.sequence([
                        SKAction.group([knockback, fadeOut]),
                        SKAction.removeFromParent()
                    ]))
                    
                    spawnerManager.activeSnakes.remove(at: snakeIndex)
                    break
                }
            }
            
            if hit {
                projectile.removeFromParent()
                activeProjectiles.remove(at: projIndex)
            }
        }
    }
}
