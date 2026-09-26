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

    private var storyStartingWoodPosition: CGPoint?
    private var storyStartingCapybaraPosition: CGPoint?
    
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
    var pauseButtonNode: SKNode?
    var pauseOverlayContainer: SKNode?
    private var gameOverOverlay: SKNode?
    var isGamePaused: Bool = false
    private var isCrocodileEating = false
    private var isResuming = false
    private var countdownLabel: SKLabelNode?
    
    var throwCooldownRing: SKShapeNode?
    var isThrowOnCooldown: Bool = false
    let throwCooldownDuration: TimeInterval = 1.5
    var scoreLabel: SKLabelNode?
    private var lifeIcons: [SKSpriteNode] = []
    private var bgMusicNode: SKAudioNode?
    
    let riverTopMargin: CGFloat = 90.0
    let woodZPosition: CGFloat = 11
    let capyZPosition: CGFloat = 12
    
    override func didMove(to view: SKView) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        self.view?.isMultipleTouchEnabled = true
        viewModel.reset()
        
        isGamePaused = false
        isThrowOnCooldown = false
        throwButton?.alpha = 1.0
        throwCooldownRing?.path = nil
        
        scoreLabel = self.childNode(withName: "//scoreLabel") as? SKLabelNode
        scoreLabel?.text = "Score: 0"
        
        setupWoodAndPlayers()
        setupLifeHUD()
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
        setupPauseOverlay()
    }
    
    private func setupLifeHUD() {
        lifeIcons.forEach { $0.removeFromParent() }
        lifeIcons.removeAll()

        for index in 0..<3 {
            let icon = SKSpriteNode(imageNamed: "capy_head")
            icon.name = "lifeIcon\(index)"
            icon.size = CGSize(width: 90, height: 90)
            icon.position = CGPoint(
                x: -size.width / 2 + 125 + CGFloat(index) * 105,
                y: size.height / 2 - 145
            )
            icon.zPosition = 500
            addChild(icon)
            lifeIcons.append(icon)
        }

        updateLifeHUD()
    }

    private func updateLifeHUD() {
        let livingCount = capySlots.compactMap { $0 }.count

        for (index, icon) in lifeIcons.enumerated() {
            icon.alpha = index < livingCount ? 1.0 : 0.25
        }
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
    
    func configureStoryStart(woodPosition: CGPoint, capybaraPosition: CGPoint) {
        storyStartingWoodPosition = woodPosition
        storyStartingCapybaraPosition = capybaraPosition
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

        applyStoryStartingStateIfNeeded()
    }

    private func applyStoryStartingStateIfNeeded() {
        // Setiap permainan baru, termasuk restart, mulai dengan 1 capybara.
        for index in capySlots.indices where index != 1 {
            capySlots[index]?.removeFromParent()
            capySlots[index] = nil
        }

        guard
            let woodPosition = storyStartingWoodPosition,
            let capybaraPosition = storyStartingCapybaraPosition,
            let wood,
            let survivor = capySlots[1]
        else {
            return
        }

        wood.position = woodPosition
        survivor.position = capybaraPosition
        slotOffsets[1] = CGPoint(
            x: capybaraPosition.x - woodPosition.x,
            y: capybaraPosition.y - woodPosition.y
        )
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
        let buttonSize = CGSize(width: 220, height: 220)
        if let existingPause = self.childNode(withName: "//pauseButton") {
            existingPause.zPosition = 95
            pauseButtonNode = existingPause
        }
        
        self.childNode(withName: "//throwButton")?.removeFromParent()
        let throwSprite = SKSpriteNode(imageNamed: "throw_rock_button")
        throwSprite.name = "throwButton"
        throwSprite.size = buttonSize
        throwSprite.position = CGPoint(x: size.width / 2 - 145, y: -size.height / 2 + 275)
        throwSprite.zPosition = 90
        addChild(throwSprite)
        throwButton = throwSprite
        
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
        
        self.childNode(withName: "//jumpButton")?.removeFromParent()
        let jumpSprite = SKSpriteNode(imageNamed: "jump_button")
        jumpSprite.name = "jumpButton"
        jumpSprite.size = buttonSize
        jumpSprite.position = CGPoint(x: size.width / 2 - 335, y: -size.height / 2 + 135)
        jumpSprite.zPosition = 90
        addChild(jumpSprite)
        jumpButton = jumpSprite
    }
    
    // MARK: - Pause Overlay & Logic
    private func setupPauseOverlay() {
        let container = SKNode()
        container.zPosition = 1000
        container.isHidden = true
        
        // Dark semi-transparent dimming background
        let dimBg = SKShapeNode(rectOf: CGSize(width: 5000, height: 5000))
        dimBg.fillColor = SKColor.black.withAlphaComponent(0.5)
        dimBg.strokeColor = .clear
        dimBg.zPosition = 0
        container.addChild(dimBg)
        
        if let overlayScene = SKScene(fileNamed: "PauseOverlay") {
            let children = overlayScene.children
            for child in children {
                child.removeFromParent()
                child.zPosition += 1
                container.addChild(child)
            }
        }
        
        container.position = .zero
        addChild(container)
        pauseOverlayContainer = container
    }
    
    func showGameOver() {
        guard gameOverOverlay == nil else { return }

        let overlay = SKNode()
        overlay.zPosition = 2000

        let dimBackground = SKShapeNode(rectOf: size)
        dimBackground.fillColor = .black.withAlphaComponent(0.6)
        dimBackground.strokeColor = .clear
        overlay.addChild(dimBackground)
        
        let content = SKNode()
        content.position = .zero
        content.zPosition = 1
        overlay.addChild(content)
        
        let panel = SKSpriteNode(imageNamed: "pause_background")
        panel.size = CGSize(width: 1000, height: 850)
        content.addChild(panel)

        func addLabel(
            _ text: String,
            y: CGFloat,
            fontSize: CGFloat,
            color: SKColor = SKColor(red: 0.22, green: 0.16, blue: 0.10, alpha: 1)
        ) {
            let label = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
            label.text = text
            label.fontSize = fontSize
            label.fontColor = color
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: 0, y: y)
            label.zPosition = 2
            content.addChild(label)
        }

        let finalScore = viewModel.score
        let highScore = UserDefaults.standard.integer(forKey: "BestScore")
        
        addLabel("GAME OVER", y: 260, fontSize: 62)
        addLabel("FINAL SCORE", y: 120, fontSize: 32)
        addLabel("\(finalScore)", y: 35, fontSize: 96)
        addLabel("HIGH SCORE: \(highScore)", y: -70, fontSize: 32)

        let restartButton = SKSpriteNode(imageNamed: "button/restart_button")
        restartButton.name = "gameOverRestartButton"
        restartButton.size = CGSize(width: 390, height: 120)
        restartButton.position = CGPoint(x: 0, y: -190)
        restartButton.zPosition = 3
        content.addChild(restartButton)

        let homeButton = SKSpriteNode(imageNamed: "button/home_button")
        homeButton.name = "gameOverHomeButton"
        homeButton.size = CGSize(width: 330, height: 110)
        homeButton.position = CGPoint(x: 0, y: -325)
        homeButton.zPosition = 3
        content.addChild(homeButton)

        addChild(overlay)
        gameOverOverlay = overlay
        joystick.resetVelocity()
        self.speed = 0
    }
    
    func pauseGame() {
        guard !viewModel.isGameOverTriggered && !isGamePaused else { return }
        isGamePaused = true
        pauseOverlayContainer?.isHidden = false
        joystick.resetTouch()
        self.speed = 0.0
    }
    
    func resumeGame() {
        guard isGamePaused, !isResuming else { return }

        isResuming = true
        pauseOverlayContainer?.isHidden = true
        joystick.resetTouch()

        let label = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        label.fontSize = 150
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
        label.zPosition = 3000
        label.text = "3"
        addChild(label)
        countdownLabel = label

        // DispatchQueue dipakai karena SKAction ikut berhenti saat scene.speed = 0.
        for (step, text) in ["2", "1", "GO!"].enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step + 1)) { [weak self] in
                guard let self, self.isResuming, self.view?.scene === self else { return }
                label.text = text
                label.fontSize = text == "GO!" ? 110 : 150
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            guard let self, self.isResuming, self.view?.scene === self else { return }

            label.removeFromParent()
            self.countdownLabel = nil
            self.isResuming = false
            self.isGamePaused = false
            self.speed = 1.0
        }
    }
    
    func restartGame() {
        self.speed = 1.0
        bgMusicNode?.run(SKAction.stop())
        bgMusicNode?.removeFromParent()
        
        if let newScene = SKScene(fileNamed: "GameScene") {
            newScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 0.5)
            self.view?.presentScene(newScene, transition: transition)
        }
    }
    
    func goToHome() {
        self.speed = 1.0
        bgMusicNode?.run(SKAction.stop())
        bgMusicNode?.removeFromParent()
        
        if let homeScene = SKScene(fileNamed: "MainMenuScene") {
            homeScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 0.5)
            self.view?.presentScene(homeScene, transition: transition)
        }
    }
    
    private func isNodeOrAncestorNamed(_ node: SKNode, name: String) -> Bool {
        var current: SKNode? = node
        while let n = current {
            if n.name == name { return true }
            current = n.parent
        }
        return false
    }
    
    private func playButtonSound() {
        run(SKAction.playSoundFileNamed("button_clicked.mp3", waitForCompletion: false))
    }

    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    // MARK: - Touch Input Handlers
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            if viewModel.isGameOverTriggered {
                for node in nodes(at: location) {
                    if isNodeOrAncestorNamed(node, name: "gameOverRestartButton") {
                        playButtonSound()
                        restartGame()
                        return
                    }

                    if isNodeOrAncestorNamed(node, name: "gameOverHomeButton") {
                        playButtonSound()
                        goToHome()
                        return
                    }
                }
                return
            }
            
            // Check Overlay Touch when Paused
            if isGamePaused {
                if let container = pauseOverlayContainer {
                    let overlayLocation = touch.location(in: container)
                    let touchedNodes = container.nodes(at: overlayLocation)
                    for node in touchedNodes {
                        if isNodeOrAncestorNamed(node, name: "resumeButton") {
                            playButtonSound()
                            resumeGame()
                            return
                        } else if isNodeOrAncestorNamed(node, name: "restartButton") {
                            playButtonSound()
                            restartGame()
                            return
                        } else if isNodeOrAncestorNamed(node, name: "homeButton") {
                            playButtonSound()
                            goToHome()
                            return
                        }
                    }
                }
                return
            }
            
            // Check Pause Button Touch
            if let pauseBtn = pauseButtonNode {
                if pauseBtn.contains(location) || self.nodes(at: location).contains(where: { isNodeOrAncestorNamed($0, name: "pauseButton") }) {
                    playButtonSound()
                    pauseGame()
                    return
                }
            }
            
            if joystick.handleTouchBegan(touch, location: location) {
                continue
            }
            if let throwNode = throwButton, throwNode.contains(location) { 
                playButtonSound()
                performThrow() 
            }
            if let jumpNode = jumpButton, jumpNode.contains(location) { 
                playButtonSound()
                performJump() 
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGamePaused { return }
        for touch in touches {
            let location = touch.location(in: self)
            joystick.handleTouchMoved(touch, location: location)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGamePaused { return }
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
        
        let ringRadius: CGFloat = 118.0
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
        self?.throwButton?.alpha = 1.0
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
        if isGamePaused {
            joystick.resetVelocity()
            return
        }
        
        if viewModel.isGameOverTriggered {
            joystick.resetVelocity()
        } else {
            viewModel.updateScore(deltaTime: 1.0 / 60.0) { [weak self] newScore in
                self?.scoreLabel?.text = "Score: \(newScore)"
            }
        }
        
        let leftOffScreen = -size.width - 1000.0
        
        // KONDISI KALAH 1: Semua capybara mati
        if !viewModel.isGameOverTriggered && !isCrocodileEating {
            let hasLivingCapy = capySlots.contains { $0 != nil }
            let hasDyingCapy = children.contains { $0.name == "dying_capy" }

            if !hasLivingCapy && !hasDyingCapy {
                viewModel.triggerGameOver(in: self)
                return
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
        
        // Gerak capybara dibuat 100% sebanding/proporsional dengan kecepatan sungai
        let gerakSpeed: CGFloat = 7.0 * CGFloat(viewModel.difficultyMultiplier)
        
        var targetVelocityX = (joystick.velocity.dx * gerakSpeed) + viewModel.woodBackwardSpeed
        let targetVelocityY = joystick.velocity.dy * gerakSpeed
        let friction: CGFloat = 0.20
        
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
        
        if isBlockedByRock { 
            if !viewModel.isRecovering {
                triggerHapticFeedback()
            }
            viewModel.isRecovering = true 
        }
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
        if !isJumping, !viewModel.isGameOverTriggered, !isCrocodileEating, capySlots.contains(where: { $0 != nil }) {
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
                                updateLifeHUD()
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
        
        checkCrocodileCollisions(isJumping: isJumping)
        updateSnakes(isJumping: isJumping, leftOffScreen: leftOffScreen)
        updateProjectiles()
    }
    
    // MARK: - Crocodile Obstacle Logic
    private func checkCrocodileCollisions(isJumping: Bool) {
        guard let w = wood, !isJumping, !viewModel.isGameOverTriggered else { return }
        
        let livingCapys = capySlots.compactMap { $0 }
        
        for croc in spawnerManager.activeCrocodiles {
            for capy in livingCapys {
                // Menyesuaikan hitbox ke posisi mulut buaya (di sebelah kiri atas sprite)
                let crocMouthX = croc.position.x - (croc.size.width * 0.35)
                let crocMouthY = croc.position.y + (croc.size.height * 0.20)
                
                let dx = abs(crocMouthX - capy.position.x)
                let dy = abs(crocMouthY - capy.position.y)
                
                // Tabrakan presisi hanya dengan mulut buaya
                if dx < 30.0 && dy < 30.0 {
                    triggerCrocodileEat(croc: croc)
                    return // Game Over triggered, stop checking
                }
            }
        }
    }
    
    private func triggerCrocodileEat(croc: SKSpriteNode) {
        guard !viewModel.isGameOverTriggered && !isCrocodileEating else { return }
        isCrocodileEating = true

        triggerHapticFeedback()
        run(SKAction.playSoundFileNamed("fall_capy.mp3", waitForCompletion: false))
        
        let mouthOpenTexture = SKTexture(imageNamed: "crocodile/crocodile_2")
        let mouthClosedTexture = SKTexture(imageNamed: "crocodile/crocodile_1")
        
        // Open mouth wide (Mangap!)
        croc.texture = mouthOpenTexture
        
        // Hide wood & capybaras (swallowed by crocodile)
        wood?.isHidden = true
        for i in 0..<3 {
            capySlots[i]?.isHidden = true
            capySlots[i] = nil
        }
        updateLifeHUD()
        
        // Sequence: Hold mouth open for 0.4s (eating), close mouth (mingkep), then show Game Over screen
        let waitEating = SKAction.wait(forDuration: 0.4)
        let closeMouth = SKAction.run {
            croc.texture = mouthClosedTexture
        }
        let delayGameOver = SKAction.wait(forDuration: 0.2)
        let showGameOver = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.viewModel.triggerGameOver(in: self)
        }
        
        croc.run(SKAction.sequence([waitEating, closeMouth, delayGameOver, showGameOver]))
    }
    
    // MARK: - Snake State Machine

    private enum SnakeState: String {
        case approach   // Fase 1: ngincer & ngejar capybara dari kanan
        case paused     // Fase 2: baru lewatin capybara, "mikir" dulu sebelum muter
        case windup     // Fase 3: mulai muter balik, speed & turn rate ramp-up (window buat dodge!)
        case strike     // Fase 4: full speed ngejar balik, terkunci ke target
    }

    // Tuning knobs — ubah di sini buat rasain beda feel-nya
    private let snakePauseDuration: CGFloat = 0.5      // durasi "mikir" sebelum mulai muter (detik)
    private let snakeWindupDuration: CGFloat = 0.5     // durasi ramp-up sebelum full strike (detik)
    private let snakeApproachTurnRateFar: CGFloat = 0.08
    private let snakeApproachTurnRateNear: CGFloat = 0.08
    private let snakeStrikeTurnRate: CGFloat = 0.05
    private let snakeStrikeSpeedMult: CGFloat = 1.8
    private let snakeWindupStartTurnRate: CGFloat = 0.01
    private let snakeWindupStartSpeedMult: CGFloat = 0.5
    private let snakeProximityBoostRadius: CGFloat = 300.0
    private let snakeProximityBoostMult: CGFloat = 1.5

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
            let distanceToTarget = hypot(realDx, realDy)
            let hasPassedPlayer = realDx > 0

            var state = SnakeState(rawValue: enemy.userData?["snakeState"] as? String ?? "") ?? .approach
            var stateTimer = (enemy.userData?["stateTimer"] as? CGFloat) ?? 0

            // --- State transitions ---
            switch state {
            case .approach:
                if hasPassedPlayer {
                    state = .paused
                    stateTimer = 0
                }
            case .paused:
                stateTimer += dt
                if stateTimer >= snakePauseDuration {
                    state = .windup
                    stateTimer = 0
                }
            case .windup:
                stateTimer += dt
                if stateTimer >= snakeWindupDuration {
                    state = .strike
                    stateTimer = 0
                }
            case .strike:
                break // fase final, nggak balik lagi ke approach walau realDx berubah tanda
            }

            enemy.userData?["snakeState"] = state.rawValue
            enemy.userData?["stateTimer"] = stateTimer

            // --- Target angle per state ---
            let targetAngle: CGFloat
            switch state {
            case .approach:
                targetAngle = atan2(realDy, realDx)
            case .paused:
                targetAngle = CGFloat.pi // berenang lurus ke kiri, belum muter
            case .windup, .strike:
                targetAngle = atan2(realDy, realDx) // mulai ngincer lagi
            }

            var currentAngle = (enemy.userData?["currentAngle"] as? CGFloat) ?? CGFloat.pi
            var angleDiff = targetAngle - currentAngle
            while angleDiff < -.pi { angleDiff += 2 * .pi }
            while angleDiff > .pi { angleDiff -= 2 * .pi }

            // --- Turn rate & move speed per state ---
            let maxTurnRate: CGFloat
            let moveSpeed: CGFloat

            switch state {
            case .approach:
                maxTurnRate = distanceToTarget > 250 ? snakeApproachTurnRateFar : snakeApproachTurnRateNear
                
                // Sprint logic: Ular lari cepat (ngejar) secara natural dengan smooth transition
                let xDist = abs(realDx)
                let sprintMultiplier: CGFloat
                if xDist > 450 {
                    sprintMultiplier = 3.5
                } else if xDist < 150 {
                    sprintMultiplier = 1.0
                } else {
                    // Smooth linear interpolation dari 1.0 ke 3.5
                    let progress = (xDist - 150) / 300.0
                    sprintMultiplier = 1.0 + (2.5 * progress)
                }
                moveSpeed = viewModel.snakeSpeed * sprintMultiplier
            case .paused:
                maxTurnRate = snakeApproachTurnRateNear
                moveSpeed = viewModel.snakeSpeed
            case .windup:
                let progress = min(stateTimer / snakeWindupDuration, 1.0)
                maxTurnRate = snakeWindupStartTurnRate + (snakeStrikeTurnRate - snakeWindupStartTurnRate) * progress
                moveSpeed = viewModel.snakeSpeed * (snakeWindupStartSpeedMult + (snakeStrikeSpeedMult - snakeWindupStartSpeedMult) * progress)
            case .strike:
                maxTurnRate = snakeStrikeTurnRate
                let proximityBoost = distanceToTarget < snakeProximityBoostRadius ? snakeProximityBoostMult : 1.0
                moveSpeed = viewModel.snakeSpeed * snakeStrikeSpeedMult * proximityBoost
            }

            let turn = max(-maxTurnRate, min(maxTurnRate, angleDiff))
            currentAngle += turn
            while currentAngle < -.pi { currentAngle += 2 * .pi }
            while currentAngle > .pi { currentAngle -= 2 * .pi }

            enemy.userData?["currentAngle"] = currentAngle

            enemy.position.x += cos(currentAngle) * moveSpeed
            enemy.position.y += sin(currentAngle) * moveSpeed

            // Enforce strict River Y boundaries so snakes stay inside river
            let minRiverY = -size.height / 2 + 170.0
            let maxRiverY = -40.0

            if enemy.position.y > maxRiverY {
                enemy.position.y = maxRiverY
                // Biarkan angle tetap menargetkan capybara agar gerakan sliding-nya mulus, tidak patah-patah
            } else if enemy.position.y < minRiverY {
                enemy.position.y = minRiverY
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
            // Hitbox ular diperbesar agar tidak mudah miss/nembus saat kecepatan tinggi
            let hitRadius: CGFloat = 45.0

            for i in 0..<3 {
                if let capy = capySlots[i] {
                    let dxHit = capy.position.x - enemy.position.x
                    let dyHit = capy.position.y - enemy.position.y

                    if hypot(dxHit, dyHit) < hitRadius && !isJumping {
                        triggerHapticFeedback()
                        capySlots[i] = nil
                        updateLifeHUD()
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
                let dxHit = abs(projectile.position.x - enemy.position.x)
                let dyHit = abs(projectile.position.y - enemy.position.y)
                
                // Gunakan bounding box yang lebih lebar agar tidak "nembus" visual ular
                if dxHit < 80.0 && dyHit < 100.0 {
                    hit = true
                    run(SKAction.playSoundFileNamed("fall_capy.mp3", waitForCompletion: false))
                    
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
            
            if !hit {
                for croc in spawnerManager.activeCrocodiles {
                    let dxHit = projectile.position.x - croc.position.x
                    let dyHit = projectile.position.y - croc.position.y
                    
                    if hypot(dxHit, dyHit) < 80.0 {
                        hit = true
                        let mouthOpenTexture = SKTexture(imageNamed: "crocodile/crocodile_2")
                        let mouthClosedTexture = SKTexture(imageNamed: "crocodile/crocodile_1")
                        croc.texture = mouthOpenTexture
                        croc.run(SKAction.sequence([
                            SKAction.wait(forDuration: 0.25),
                            SKAction.run { croc.texture = mouthClosedTexture }
                        ]))
                        break
                    }
                }
            }
            
            if hit {
                projectile.removeFromParent()
                activeProjectiles.remove(at: projIndex)
            }
        }
    }
}
