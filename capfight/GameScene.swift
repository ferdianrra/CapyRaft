import SpriteKit

class GameScene: SKScene {
    
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
    
    var joystickBase: SKShapeNode!
    var joystickKnob: SKShapeNode!
    var isJoystickActive = false
    var joystickTouch: UITouch?
    var joystickVelocity = CGVector.zero
    var currentVelocity = CGVector.zero
    
    var snakeTemplate: SKSpriteNode?
    var activeSnakes: [SKSpriteNode] = []
    var snakeAnimation: SKAction!
    
    var rockTemplate: SKSpriteNode?
    var activeRocks: [SKSpriteNode] = []
    
    var capyHelpTemplate: SKSpriteNode?
    var activeCapyHelps: [SKSpriteNode] = []
    
    var activeProjectiles: [SKSpriteNode] = []
    
    var throwButton: SKNode!
    var jumpButton: SKNode!
    
    var scoreLabel: SKLabelNode?
    var score: Int = 0
    var scoreTimer: TimeInterval = 0
    
    let baseRadius: CGFloat = 60.0
    let riverTopMargin: CGFloat = 90.0
    
    let woodZPosition: CGFloat = 1
    let capyZPosition: CGFloat = 2
    
    // Status kondisi permainan
    var isGameOverTriggered = false
    var isRecovering = false // Penanda jika kayu sedang terseret di belakang batas aman
    
    override func didMove(to view: SKView) {
        self.view?.isMultipleTouchEnabled = true
        score = 0
        isGameOverTriggered = false
        isRecovering = false
        
        scoreLabel = self.childNode(withName: "//scoreLabel") as? SKLabelNode
        scoreLabel?.text = "Score: 0"
        
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
        
        if let snakeNode = self.childNode(withName: "//snake") as? SKSpriteNode {
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
            
            startSnakeSpawner()
        }
        
        var foundRock = self.childNode(withName: "//rock_obstacle") as? SKSpriteNode
        if foundRock == nil { foundRock = self.childNode(withName: "//rock") as? SKSpriteNode }
        if foundRock == nil { foundRock = self.childNode(withName: "//Rock") as? SKSpriteNode }
        
        if let rockNode = foundRock {
            rockTemplate = rockNode
            rockTemplate?.removeFromParent()
            startRockSpawner()
        }
        
        if let helpNode = self.childNode(withName: "//capy_help") as? SKSpriteNode {
            capyHelpTemplate = helpNode
            capyHelpTemplate?.removeFromParent()
            startCapyHelpSpawner()
        }
        
        bg1 = self.childNode(withName: "//bg1") as? SKSpriteNode
        bg2 = self.childNode(withName: "//bg2") as? SKSpriteNode
        forest1 = self.childNode(withName: "//forest1") as? SKSpriteNode
        forest2 = self.childNode(withName: "//forest2") as? SKSpriteNode
        
        setupJoystick()
        setupButtons()
    }
    
    func startSnakeSpawner() {
        let waitAction = SKAction.wait(forDuration: 2.5, withRange: 1.5)
        let spawnAction = SKAction.run { [weak self] in self?.spawnSingleSnake() }
        self.run(SKAction.repeatForever(SKAction.sequence([waitAction, spawnAction])))
    }
    
    func spawnSingleSnake() {
        guard let template = snakeTemplate, let newSnake = template.copy() as? SKSpriteNode else { return }
        newSnake.isHidden = false
        let spawnY = CGFloat.random(in: -size.height / 2 + 180 ... -40.0)
        newSnake.position = CGPoint(x: size.width / 2 + 150, y: spawnY)
        newSnake.run(snakeAnimation)
        self.addChild(newSnake)
        activeSnakes.append(newSnake)
    }
    
    func startRockSpawner() {
        let waitAction = SKAction.wait(forDuration: 3.5, withRange: 1.0)
        let spawnAction = SKAction.run { [weak self] in self?.spawnSingleRock() }
        self.run(SKAction.repeatForever(SKAction.sequence([waitAction, spawnAction])))
    }
    
    func spawnSingleRock() {
        guard let template = rockTemplate, let newRock = template.copy() as? SKSpriteNode else { return }
        newRock.isHidden = false
        let spawnY = CGFloat.random(in: -size.height / 2 + 180 ... -40.0)
        newRock.position = CGPoint(x: size.width / 2 + 150, y: spawnY)
        self.addChild(newRock)
        activeRocks.append(newRock)
    }
    
    func startCapyHelpSpawner() {
        let waitAction = SKAction.wait(forDuration: 9.0, withRange: 3.0)
        let spawnAction = SKAction.run { [weak self] in self?.spawnSingleCapyHelp() }
        self.run(SKAction.repeatForever(SKAction.sequence([waitAction, spawnAction])))
    }
    
    func spawnSingleCapyHelp() {
        guard let template = capyHelpTemplate, let newHelp = template.copy() as? SKSpriteNode else { return }
        newHelp.isHidden = false
        let spawnY = CGFloat.random(in: -size.height / 2 + 180 ... -40.0)
        newHelp.position = CGPoint(x: size.width / 2 + 150, y: spawnY)
        self.addChild(newHelp)
        activeCapyHelps.append(newHelp)
    }
    
    func setupJoystick() {
        joystickBase = SKShapeNode(circleOfRadius: baseRadius)
        joystickBase.strokeColor = .white
        joystickBase.lineWidth = 3
        joystickBase.alpha = 0.5
        joystickBase.position = CGPoint(x: -size.width / 2 + 120, y: -size.height / 2 + 120)
        joystickBase.zPosition = 10
        addChild(joystickBase)
        
        joystickKnob = SKShapeNode(circleOfRadius: 30)
        joystickKnob.fillColor = .white
        joystickKnob.position = joystickBase.position
        joystickKnob.zPosition = 11
        addChild(joystickKnob)
    }
    
    func setupButtons() {
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
    
    func performThrow() {
        if isGameOverTriggered { return }
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
        
        let offsetPosisitionX: CGFloat = isFacingRight ? 50.0 : -50.0
        rockProjectile.position = CGPoint(x: frontCapy.position.x + offsetPosisitionX, y: frontCapy.position.y)
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
        if isGameOverTriggered || wood?.action(forKey: "jumping") != nil { return }
        
        let jumpUp = SKAction.moveBy(x: 0, y: 150, duration: 0.3)
        jumpUp.timingMode = .easeOut
        let jumpDown = SKAction.moveBy(x: 0, y: -150, duration: 0.3)
        jumpDown.timingMode = .easeIn
        let jumpSequence = SKAction.sequence([jumpUp, jumpDown])
        
        wood?.run(jumpSequence, withKey: "jumping")
    }
    
    func triggerGameOver() {
        if isGameOverTriggered { return }
        isGameOverTriggered = true
        
        let currentBest = UserDefaults.standard.integer(forKey: "BestScore")
        if score > currentBest {
            UserDefaults.standard.set(score, forKey: "BestScore")
        }
        
        // Beri jeda 1 detik agar player bisa melihat momen kekalahannya
        let waitAndGo = SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                if let menuScene = SKScene(fileNamed: "MainMenuScene") {
                    menuScene.scaleMode = .aspectFill
                    let transition = SKTransition.fade(withDuration: 0.8)
                    self?.view?.presentScene(menuScene, transition: transition)
                }
            }
        ])
        self.run(waitAndGo)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if joystickBase.contains(location) && joystickTouch == nil {
                isJoystickActive = true
                joystickTouch = touch
            }
            if let throwNode = throwButton, throwNode.contains(location) { performThrow() }
            if let jumpNode = jumpButton, jumpNode.contains(location) { performJump() }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isJoystickActive { return }
        for touch in touches {
            if touch == joystickTouch {
                let location = touch.location(in: self)
                let dx = location.x - joystickBase.position.x
                let dy = location.y - joystickBase.position.y
                let distance = hypot(dx, dy)
                let angle = atan2(dy, dx)
                
                let constrainedDistance = min(distance, baseRadius)
                let knobX = constrainedDistance * cos(angle)
                let knobY = constrainedDistance * sin(angle)
                
                joystickKnob.position = CGPoint(x: joystickBase.position.x + knobX, y: joystickBase.position.y + knobY)
                joystickVelocity = CGVector(dx: knobX / baseRadius, dy: knobY / baseRadius)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch == joystickTouch {
                isJoystickActive = false
                joystickTouch = nil
                
                let resetKnob = SKAction.move(to: joystickBase.position, duration: 0.15)
                resetKnob.timingMode = .easeOut
                joystickKnob.run(resetKnob)
                joystickVelocity = CGVector.zero
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        // Hentikan kendali saat Game Over, tapi biarkan alam tetap bergerak
        if isGameOverTriggered {
            joystickVelocity = .zero
        } else {
            scoreTimer += 1.0 / 60.0
            if scoreTimer >= 1.0 {
                score += 10
                scoreLabel?.text = "Score: \(score)"
                scoreTimer = 0
            }
        }
        
        let difficultyMultiplier = 1.0 + (Double(score) / 200.0)
        
        let riverSpeed: CGFloat = CGFloat(2.0 * difficultyMultiplier)
        let forestSpeed: CGFloat = 0.5
        let obstacleSpeed: CGFloat = CGFloat(3.0 * difficultyMultiplier)
        
        // Jauhkan batas hapus agar batu benar-benar berhasil menarik kayu sampai keluar layar penuh
        let leftOffScreen = -size.width - 1000.0
        
        // KONDISI KALAH 1: Semua capybara mati
        if !isGameOverTriggered {
            let livingCapys = capySlots.compactMap { $0 }
            let dyingCapys = self.children.filter { $0.name == "dying_capy" }
            
            // Akan menunggu animasi capybara terakhir (dyingCapys) benar-benar selesai
            if livingCapys.isEmpty && dyingCapys.isEmpty {
                triggerGameOver()
            }
        }
        
        if let b1 = bg1, let b2 = bg2 {
            b1.position.x -= riverSpeed
            b2.position.x -= riverSpeed
            if b1.position.x <= -b1.size.width { b1.position.x = b2.position.x + b2.size.width }
            if b2.position.x <= -b2.size.width { b2.position.x = b1.position.x + b1.size.width }
        }
        
        if let f1 = forest1, let f2 = forest2 {
            f1.position.x -= forestSpeed
            f2.position.x -= forestSpeed
            if f1.position.x <= -f1.size.width { f1.position.x = f2.position.x + f2.size.width }
            if f2.position.x <= -f2.size.width { f2.position.x = f1.position.x + f1.size.width }
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
        
        if let w = wood {
            let isJumping = w.action(forKey: "jumping") != nil
            
            let gerakSpeed: CGFloat = 8.0
            let efekMundur: CGFloat = CGFloat(-3.0 * difficultyMultiplier)
            var targetVelocityX = (joystickVelocity.dx * gerakSpeed) + efekMundur
            let targetVelocityY = joystickVelocity.dy * gerakSpeed
            let friction: CGFloat = 0.15
            
            currentVelocity.dx += (targetVelocityX - currentVelocity.dx) * friction
            currentVelocity.dy += (targetVelocityY - currentVelocity.dy) * friction
            
            w.position.x += currentVelocity.dx
            w.position.y += currentVelocity.dy
            
            var isBlockedByRock = false
            if !isJumping {
                for rock in activeRocks {
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
                targetVelocityX = -obstacleSpeed
            }
            
            // LOGIKA PEMBATAS LAYAR BARU
            let marginX: CGFloat = 200.0
            let normalMinX = -size.width / 2 + marginX
            let maxX = size.width / 2 - marginX
            
            // Jika kena batu, status menjadi isRecovering (tertinggal di belakang)
            if isBlockedByRock { isRecovering = true }
            // Jika berhasil maju melewati garis aman lagi, status kembali aman
            if w.position.x >= normalMinX { isRecovering = false }
            
            // Jika sedang tertinggal/terseret, matikan pembatas layarnya
            let appliedMinX = isRecovering ? (-size.width - 1000.0) : normalMinX
            
            if joystickVelocity.dx < -0.1 { w.xScale = -originalWoodScale }
            else if joystickVelocity.dx > 0.1 { w.xScale = originalWoodScale }
            
            let isFacingRight = w.xScale > 0
            let minY = (-size.height / 2 + 180) - slotOffsets[0].y
            let maxY = riverTopMargin - slotOffsets[0].y
            
            if !isJumping { w.position.y = max(minY, min(maxY, w.position.y)) }
            else { w.position.y = max(minY, w.position.y) }
            
            w.position.x = max(appliedMinX, min(maxX, w.position.x))
            
            // KONDISI KALAH 2: Kayu benar-benar hilang dari layar sebelah kiri
            if !isGameOverTriggered {
                let woodRightEdge = w.position.x + (w.size.width / 2)
                if woodRightEdge < -size.width / 2 {
                    triggerGameOver()
                }
            }
            
            if !isJumping {
                for (index, help) in activeCapyHelps.enumerated().reversed() {
                    if hypot(w.position.x - help.position.x, w.position.y - help.position.y) < 120.0 {
                        help.removeFromParent()
                        activeCapyHelps.remove(at: index)
                        
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
            
            for i in 0..<3 {
                if let capy = capySlots[i] {
                    let offX = isFacingRight ? slotOffsets[i].x : -slotOffsets[i].x
                    capy.position = CGPoint(x: w.position.x + offX, y: w.position.y + slotOffsets[i].y)
                    capy.xScale = isFacingRight ? originalCapyScale : -originalCapyScale
                }
            }
            
            for (index, enemy) in activeSnakes.enumerated().reversed() {
                
                let livingCapyNodes = capySlots.compactMap { $0 }
                guard let chaseTarget = livingCapyNodes.min(by: {
                    hypot($0.position.x - enemy.position.x, $0.position.y - enemy.position.y) <
                    hypot($1.position.x - enemy.position.x, $1.position.y - enemy.position.y)
                }) else { continue }
                
                let enemySpeed: CGFloat = CGFloat(3.4 * difficultyMultiplier)
                let dx = chaseTarget.position.x - enemy.position.x
                let dy = isJumping ? 0 : (chaseTarget.position.y - enemy.position.y)
                let angle = atan2(dy, dx)
                
                enemy.position.x += cos(angle) * enemySpeed
                enemy.position.y += sin(angle) * enemySpeed
                
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
                            capy.name = "dying_capy" // Tanda agar Game Over menunggu animasi ini
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
                            activeSnakes.remove(at: index)
                            snakeHit = true
                            break
                        }
                    }
                }
                
                if snakeHit { continue }
                
                if enemy.position.x < leftOffScreen {
                    enemy.removeFromParent()
                    activeSnakes.remove(at: index)
                }
            }
            
            for (projIndex, projectile) in activeProjectiles.enumerated().reversed() {
                if projectile.parent == nil {
                    activeProjectiles.remove(at: projIndex)
                    continue
                }
                
                var hit = false
                for (snakeIndex, enemy) in activeSnakes.enumerated().reversed() {
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
                        
                        activeSnakes.remove(at: snakeIndex)
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
}
