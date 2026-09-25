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
    
    var parallaxA1: SKSpriteNode?
    var parallaxA2: SKSpriteNode?
    var parallaxB1: SKSpriteNode?
    var parallaxB2: SKSpriteNode?
    var parallaxC1: SKSpriteNode?
    var parallaxC2: SKSpriteNode?
    var parallaxD1: SKSpriteNode?
    var parallaxD2: SKSpriteNode?
    var parallaxE1: SKSpriteNode?
    var parallaxE2: SKSpriteNode?
    
    var activeProjectiles: [SKSpriteNode] = []
    var currentVelocity = CGVector.zero
    
    var throwButton: SKNode!
    var jumpButton: SKNode!
    var throwCooldownRing: SKShapeNode?
    var isThrowOnCooldown: Bool = false
    let throwCooldownDuration: TimeInterval = 2.0
    var scoreLabel: SKLabelNode?
    private var bgMusicNode: SKAudioNode?
    
    let riverTopMargin: CGFloat = 90.0
    let woodZPosition: CGFloat = 11
    let capyZPosition: CGFloat = 12
    
    override func didMove(to view: SKView) {
        self.view?.isMultipleTouchEnabled = true
        viewModel.reset()
        
        isThrowOnCooldown = false
        throwButton?.alpha = 0.7
        throwCooldownRing?.path = nil
        
        scoreLabel = self.childNode(withName: "//scoreLabel") as? SKLabelNode
        scoreLabel?.text = "Score: 0"
        
        setupWoodAndPlayers()
        setupBackgrounds()
        setupBackgroundMusic()
        
        // Setup Joystick Component
        joystick.setup(sceneSize: size)
        addChild(joystick)
        
        // Setup Spawner Manager Component
        spawnerManager.setupTemplates(in: self, getScore: { [weak self] in
            return self?.viewModel.score ?? 0
        })
        
        setupButtons()
    }
    
    private func setupBackgroundMusic() {
        if bgMusicNode == nil {
            let musicURL: URL? = Bundle.main.url(forResource: "river_ambience", withExtension: "mp3") ??
                                 Bundle.main.url(forResource: "river_ambience", withExtension: "mp3", subdirectory: "sound")
            if let url = musicURL {
                let node = SKAudioNode(url: url)
                node.autoplayLooped = true
                addChild(node)
                bgMusicNode = node
            } else {
                let node = SKAudioNode(fileNamed: "river_ambience.mp3")
                node.autoplayLooped = true
                addChild(node)
                bgMusicNode = node
            }
        }
    }
    
    private func startCapyIdleAnimation(for capy: SKSpriteNode) {
        if capy.action(forKey: "idleAnimation") == nil {
            let idleTextures = [
                SKTexture(imageNamed: "capybara_idle/capy_idle_1"),
                SKTexture(imageNamed: "capybara_idle/capy_idle_2"),
                SKTexture(imageNamed: "capybara_idle/capy_idle_3")
            ]
            let idleAnim = SKAction.repeatForever(SKAction.animate(with: idleTextures, timePerFrame: 0.2))
            capy.run(idleAnim, withKey: "idleAnimation")
        }
    }
    
    private func setupWoodAndPlayers() {
        wood = self.childNode(withName: "//Wood") as? SKSpriteNode
        wood?.texture = SKTexture(imageNamed: "half_wood")
        originalWoodScale = abs(wood?.xScale ?? 1.0)
        wood?.zPosition = woodZPosition
        
        for i in 1...3 {
            if let node = self.childNode(withName: "//MainPlayer\(i)") as? SKSpriteNode {
                capySlots[i-1] = node
                node.zPosition = capyZPosition
                startCapyIdleAnimation(for: node)
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
        func configurePair(_ n1: SKSpriteNode?, _ n2: SKSpriteNode?, zPos: CGFloat) {
            guard let node1 = n1 else { return }
            node1.zPosition = zPos
            
            let width = node1.size.width
            if let node2 = n2 {
                node2.zPosition = zPos
                node2.position = CGPoint(x: node1.position.x + width, y: node1.position.y)
            }
        }
        
        bg1 = self.childNode(withName: "//bg1") as? SKSpriteNode
        bg2 = self.childNode(withName: "//bg2") as? SKSpriteNode
        if bg2 == nil, let b1 = bg1, let clone = b1.copy() as? SKSpriteNode {
            addChild(clone)
            bg2 = clone
        }
        configurePair(bg1, bg2, zPos: 6)
        
        parallaxA1 = self.childNode(withName: "//parallax_a_bg_1") as? SKSpriteNode
        parallaxA2 = self.childNode(withName: "//parallax_a_bg_2") as? SKSpriteNode
        if parallaxA2 == nil, let p1 = parallaxA1, let clone = p1.copy() as? SKSpriteNode {
            addChild(clone)
            parallaxA2 = clone
        }
        configurePair(parallaxA1, parallaxA2, zPos: 1)
        
        parallaxB1 = self.childNode(withName: "//parallax_b_bg_1") as? SKSpriteNode
        parallaxB2 = self.childNode(withName: "//parallax_b_bg_2") as? SKSpriteNode
        if parallaxB2 == nil, let p1 = parallaxB1, let clone = p1.copy() as? SKSpriteNode {
            addChild(clone)
            parallaxB2 = clone
        }
        configurePair(parallaxB1, parallaxB2, zPos: 2)
        
        parallaxC1 = self.childNode(withName: "//parallax_c_bg_1") as? SKSpriteNode
        parallaxC2 = self.childNode(withName: "//parallax_c_bg_2") as? SKSpriteNode
        if parallaxC2 == nil, let p1 = parallaxC1, let clone = p1.copy() as? SKSpriteNode {
            addChild(clone)
            parallaxC2 = clone
        }
        configurePair(parallaxC1, parallaxC2, zPos: 3)
        
        parallaxD1 = self.childNode(withName: "//parallax_d_bg_1") as? SKSpriteNode
        parallaxD2 = self.childNode(withName: "//parallax_d_bg_2") as? SKSpriteNode
        if parallaxD2 == nil, let p1 = parallaxD1, let clone = p1.copy() as? SKSpriteNode {
            addChild(clone)
            parallaxD2 = clone
        }
        configurePair(parallaxD1, parallaxD2, zPos: 4)
        
        parallaxE1 = self.childNode(withName: "//parallax_e_bg_1") as? SKSpriteNode
        parallaxE2 = self.childNode(withName: "//parallax_e_bg_2") as? SKSpriteNode
        if parallaxE2 == nil, let p1 = parallaxE1, let clone = p1.copy() as? SKSpriteNode {
            addChild(clone)
            parallaxE2 = clone
        }
        configurePair(parallaxE1, parallaxE2, zPos: 5)
    }
    
    private func setupButtons() {
        let buttonRadius: CGFloat = 95.0
        
        if let existingThrow = self.childNode(withName: "//throwButton") {
            existingThrow.setScale(2.5)
            existingThrow.position = CGPoint(x: size.width / 2 - 180, y: -size.height / 2 + 180)
            existingThrow.zPosition = 90
            throwButton = existingThrow
        } else {
            let node = SKShapeNode(circleOfRadius: buttonRadius)
            node.fillColor = .red
            node.alpha = 0.7
            node.position = CGPoint(x: size.width / 2 - 180, y: -size.height / 2 + 180)
            node.zPosition = 90
            addChild(node)
            throwButton = node
        }
        
        // Circular Cooldown Progress Indicator Ring
        throwCooldownRing?.removeFromParent()
        let ringNode = SKShapeNode()
        ringNode.strokeColor = .yellow
        ringNode.lineWidth = 9.0
        ringNode.lineCap = .round
        ringNode.position = throwButton.position
        ringNode.zPosition = 92
        addChild(ringNode)
        throwCooldownRing = ringNode
        
        if let existingJump = self.childNode(withName: "//jumpButton") {
            existingJump.setScale(2.5)
            existingJump.position = CGPoint(x: size.width / 2 - 380, y: -size.height / 2 + 280)
            existingJump.zPosition = 90
            jumpButton = existingJump
        } else {
            let node = SKShapeNode(circleOfRadius: buttonRadius)
            node.fillColor = .blue
            node.alpha = 0.7
            node.position = CGPoint(x: size.width / 2 - 380, y: -size.height / 2 + 280)
            node.zPosition = 90
            addChild(node)
            jumpButton = node
        }
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
        if viewModel.isGameOverTriggered || isThrowOnCooldown { return }
        guard let w = wood else { return }
        let activeCapys = capySlots.compactMap { $0 }
        if activeCapys.isEmpty { return }
        
        let isFacingRight = w.xScale > 0
        guard let frontCapy = activeCapys.max(by: {
            isFacingRight ? ($0.position.x < $1.position.x) : ($0.position.x > $1.position.x)
        }) else { return }
        
        // Activate 2-Second Cooldown and Ring Animation
        isThrowOnCooldown = true
        throwButton?.alpha = 0.35
        
        let ringRadius: CGFloat = 102.0
        let duration = self.throwCooldownDuration
        let cooldownAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
            guard let shape = node as? SKShapeNode else { return }
            let progress = elapsedTime / CGFloat(duration)
            let startAngle = -CGFloat.pi / 2
            let endAngle = startAngle + (2 * CGFloat.pi * progress)
            let path = UIBezierPath(arcCenter: .zero, radius: ringRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            shape.path = path.cgPath
        }
        
        let finishAction = SKAction.run { [weak self] in
            self?.isThrowOnCooldown = false
            self?.throwButton?.alpha = 0.7
            self?.throwCooldownRing?.path = nil
        }
        
        throwCooldownRing?.removeAllActions()
        throwCooldownRing?.run(SKAction.sequence([cooldownAction, finishAction]))
        
        frontCapy.removeAction(forKey: "idleAnimation")
        let throwTextures = [
            SKTexture(imageNamed: "capybara_throw_rock/capybara_throw_rock_1"),
            SKTexture(imageNamed: "capybara_throw_rock/capybara_throw_rock_2"),
            SKTexture(imageNamed: "capybara_idle/capy_idle_1")
        ]
        let throwAnim = SKAction.animate(with: throwTextures, timePerFrame: 0.15)
        frontCapy.run(throwAnim) { [weak self] in
            self?.startCapyIdleAnimation(for: frontCapy)
        }
        
        let rockProjectile = SKSpriteNode(imageNamed: "capybara_throw_rock/rock_throw")
        rockProjectile.setScale(0.15)
        
        let offsetPositionX: CGFloat = isFacingRight ? 50.0 : -50.0
        rockProjectile.position = CGPoint(x: frontCapy.position.x + offsetPositionX, y: frontCapy.position.y)
        rockProjectile.zPosition = 15
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
        
        let woodFullTexture = SKTexture(imageNamed: "wood")
        let woodHalfTexture = SKTexture(imageNamed: "half_wood")
        
        wood?.texture = woodFullTexture
        
        let jumpUp = SKAction.moveBy(x: 0, y: 150, duration: 0.3)
        jumpUp.timingMode = .easeOut
        let jumpDown = SKAction.moveBy(x: 0, y: -150, duration: 0.3)
        jumpDown.timingMode = .easeIn
        
        let landInWater = SKAction.run { [weak self] in
            self?.wood?.texture = woodHalfTexture
        }
        
        let jumpSequence = SKAction.sequence([jumpUp, jumpDown, landInWater])
        
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
        let mult = viewModel.difficultyMultiplier
        
        // River water stream (foreground movement)
        updateParallaxPair(node1: bg1, node2: bg2, speed: viewModel.riverSpeed)
        
        // Parallax Layers: A (furthest back, slowest) to E (front-most, fastest)
        updateParallaxPair(node1: parallaxA1, node2: parallaxA2, speed: CGFloat(0.25 * mult))
        updateParallaxPair(node1: parallaxB1, node2: parallaxB2, speed: CGFloat(0.50 * mult))
        updateParallaxPair(node1: parallaxC1, node2: parallaxC2, speed: CGFloat(0.85 * mult))
        updateParallaxPair(node1: parallaxD1, node2: parallaxD2, speed: CGFloat(1.25 * mult))
        updateParallaxPair(node1: parallaxE1, node2: parallaxE2, speed: CGFloat(1.75 * mult))
        
        if let f1 = forest1, let f2 = forest2 {
            f1.position.x -= viewModel.forestSpeed
            f2.position.x -= viewModel.forestSpeed
            if f1.position.x <= -f1.size.width { f1.position.x = f2.position.x + f2.size.width }
            if f2.position.x <= -f2.size.width { f2.position.x = f1.position.x + f1.size.width }
        }
    }
    
    private func updateParallaxPair(node1: SKSpriteNode?, node2: SKSpriteNode?, speed: CGFloat) {
        guard let n1 = node1, let n2 = node2 else { return }
        let width = n1.size.width
        
        n1.position.x -= speed
        n2.position.x -= speed
        
        if n1.position.x <= -width {
            n1.position.x = n2.position.x + width
        }
        if n2.position.x <= -width {
            n2.position.x = n1.position.x + width
        }
    }
    
    private func updateWoodAndEntities(leftOffScreen: CGFloat) {
        guard let w = wood else { return }
        
        let isJumping = w.action(forKey: "jumping") != nil
        
        let gerakSpeed: CGFloat = 5.5
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
                    
                    run(SKAction.playSoundFileNamed("safe_capy.mp3", waitForCompletion: false))
                    
                    for i in 0..<3 {
                        if capySlots[i] == nil {
                            if let newChar = playerTemplate?.copy() as? SKSpriteNode {
                                newChar.zPosition = capyZPosition
                                self.addChild(newChar)
                                capySlots[i] = newChar
                                startCapyIdleAnimation(for: newChar)
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
        let dt: CGFloat = 1.0 / 60.0
        
        for (index, enemy) in spawnerManager.activeSnakes.enumerated().reversed() {
            
            let livingCapyNodes = capySlots.compactMap { $0 }
            guard let chaseTarget = livingCapyNodes.min(by: {
                hypot($0.position.x - enemy.position.x, $0.position.y - enemy.position.y) <
                hypot($1.position.x - enemy.position.x, $1.position.y - enemy.position.y)
            }) else { continue }
            
            if enemy.userData == nil { enemy.userData = NSMutableDictionary() }
            
            let realDx = chaseTarget.position.x - enemy.position.x
            let realDy = isJumping ? 0 : (chaseTarget.position.y - enemy.position.y)
            
            var canTurnAround = (enemy.userData?["canTurnAround"] as? Bool) ?? false
            var turnDelayTimer = (enemy.userData?["turnDelayTimer"] as? CGFloat) ?? 2.0
            
            let hasPassedPlayer = realDx < 0
            if hasPassedPlayer && !canTurnAround {
                turnDelayTimer -= dt
                enemy.userData?["turnDelayTimer"] = turnDelayTimer
                if turnDelayTimer <= 0 {
                    canTurnAround = true
                    enemy.userData?["canTurnAround"] = true
                }
            }
            
            let targetAngle: CGFloat
            if hasPassedPlayer && !canTurnAround {
                // Phase 2: Wait timer before turning (swim straight left)
                targetAngle = CGFloat.pi
            } else {
                // Phase 1 (Approaching from right) & Phase 3 (Chasing after U-Turn delay):
                // Actively chase capybara position!
                targetAngle = atan2(realDy, realDx)
            }
            
            var currentAngle = (enemy.userData?["currentAngle"] as? CGFloat) ?? CGFloat.pi
            
            var angleDiff = targetAngle - currentAngle
            while angleDiff < -.pi { angleDiff += 2 * .pi }
            while angleDiff > .pi { angleDiff -= 2 * .pi }
            
            // Steering rate: Smooth (0.045) when far, limited (0.025) when close so player can dodge up/down/jump!
            let maxTurnRate: CGFloat
            if realDx > 250 && !canTurnAround {
                maxTurnRate = 0.045
            } else {
                maxTurnRate = 0.025
            }
            
            let turn = max(-maxTurnRate, min(maxTurnRate, angleDiff))
            
            currentAngle += turn
            while currentAngle < -.pi { currentAngle += 2 * .pi }
            while currentAngle > .pi { currentAngle -= 2 * .pi }
            
            enemy.userData?["currentAngle"] = currentAngle
            
            // Consistent pursuit speed both before and after U-turn
            let moveSpeed = viewModel.snakeSpeed
            
            enemy.position.x += cos(currentAngle) * moveSpeed
            enemy.position.y += sin(currentAngle) * moveSpeed
            
            // Enforce strict River Y boundaries so snakes stay inside river
            let minRiverY = -size.height / 2 + 170.0
            let maxRiverY = -40.0
            
            if enemy.position.y > maxRiverY {
                enemy.position.y = maxRiverY
                if sin(currentAngle) > 0 {
                    currentAngle = (cos(currentAngle) < 0) ? (CGFloat.pi - 0.2) : -0.2
                    enemy.userData?["currentAngle"] = currentAngle
                }
            } else if enemy.position.y < minRiverY {
                enemy.position.y = minRiverY
                if sin(currentAngle) < 0 {
                    currentAngle = (cos(currentAngle) < 0) ? (CGFloat.pi + 0.2) : 0.2
                    enemy.userData?["currentAngle"] = currentAngle
                }
            }
            
            // Sprite orientation: strictly flat horizontal (zRotation = 0), flip xScale based on direction
            let originalEnemyScale = abs(enemy.xScale)
            if cos(currentAngle) < 0 {
                enemy.xScale = originalEnemyScale
                enemy.zRotation = 0
            } else {
                enemy.xScale = -originalEnemyScale
                enemy.zRotation = 0
            }
            
            var snakeHit = false
            let hitRadius: CGFloat = 26.0
            
            for i in 0..<3 {
                if let capy = capySlots[i] {
                    let dxHit = capy.position.x - enemy.position.x
                    let dyHit = capy.position.y - enemy.position.y
                    
                    if hypot(dxHit, dyHit) < hitRadius && !isJumping {
                        capySlots[i] = nil
                        capy.name = "dying_capy"
                        capy.removeAllActions()
                        
                        run(SKAction.playSoundFileNamed("fall_capy.mp3", waitForCompletion: false))
                        
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
