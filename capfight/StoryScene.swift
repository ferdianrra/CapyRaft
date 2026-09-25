import SpriteKit

final class StoryScene: SKScene {
    private let shallowRiverNode = SKSpriteNode(imageNamed: "story/sungai-dangkal")
    private let fullRiverNode = SKSpriteNode(imageNamed: "story/sungai-penuh")
    private let incomingWaterNode = SKSpriteNode(imageNamed: "story/ombak/IMG_0080")
    private let fullRiverCropNode = SKCropNode()
    private let riverRevealMaskNode = SKSpriteNode(color: .white, size: .zero)
    private let rockOverlayNode = SKSpriteNode(imageNamed: "story/batu")
    private let grassOverlayNode = SKSpriteNode(imageNamed: "story/rumput")
    private let logNode = SKSpriteNode(imageNamed: "half_wood")
    private var capybaraNodes: [SKSpriteNode] = []
    private var gameplayRiverPosition = CGPoint.zero
    private var gameplayRiverSize = CGSize.zero
    
    private var floodAudioNode: SKAudioNode?

    private var hasStarted = false

    override func didMove(to view: SKView) {
        guard !hasStarted else { return }
        hasStarted = true

        backgroundColor = UIColor(red: 0.58, green: 0.82, blue: 0.94, alpha: 1)
        buildScene()
        runStory()
    }

    private func buildScene() {
        addParallaxBackground()

        configureRiverLayer(shallowRiverNode, zPosition: 10)
        addChild(shallowRiverNode)

        configureRiverLayer(fullRiverNode, zPosition: 0)
        fullRiverCropNode.zPosition = 10
        fullRiverCropNode.addChild(fullRiverNode)

        riverRevealMaskNode.size = gameplayRiverSize == .zero ? size : gameplayRiverSize
        riverRevealMaskNode.anchorPoint = CGPoint(x: 0, y: 0.5)
        riverRevealMaskNode.position = CGPoint(
            x: gameplayRiverPosition.x - riverRevealMaskNode.size.width / 2,
            y: gameplayRiverPosition.y
        )
        riverRevealMaskNode.xScale = 0.001
        fullRiverCropNode.maskNode = riverRevealMaskNode
        addChild(fullRiverCropNode)

        configureWaveLayer(incomingWaterNode, zPosition: 11)
        incomingWaterNode.position.x = frame.minX - incomingWaterNode.size.width / 2
        addChild(incomingWaterNode)
        startWaveAnimation()

        configureRiverLayer(rockOverlayNode, zPosition: 12)
        addChild(rockOverlayNode)

        configureRiverLayer(grassOverlayNode, zPosition: 13)
        addChild(grassOverlayNode)

        addCapybaras()
        configureLog()
    }

    private func startWaveAnimation() {
        let waveFrames = [
            SKTexture(imageNamed: "story/ombak/IMG_0080"),
            SKTexture(imageNamed: "story/ombak/IMG_0081"),
            SKTexture(imageNamed: "story/ombak/IMG_0083"),
            SKTexture(imageNamed: "story/ombak/IMG_0081")
        ]
        let animation = SKAction.animate(
            with: waveFrames,
            timePerFrame: 0.14,
            resize: false,
            restore: false
        )
        incomingWaterNode.run(.repeatForever(animation), withKey: "waveAnimation")
    }

    private func addParallaxBackground() {
        guard let gameSceneTemplate = SKScene(fileNamed: "GameScene") else {
            addFallbackParallaxBackground()
            return
        }

        if let river = gameSceneTemplate.childNode(withName: "//bg1") as? SKSpriteNode {
            gameplayRiverPosition = river.position
            gameplayRiverSize = river.size
        }

        let nodeNames = [
            "parallax_a_bg_1",
            "parallax_b_bg_1",
            "parallax_c_bg_1",
            "parallax_d_bg_1",
            "parallax_e_bg_1"
        ]

        for (index, nodeName) in nodeNames.enumerated() {
            guard
                let sourceNode = gameSceneTemplate.childNode(withName: "//\(nodeName)") as? SKSpriteNode,
                let layer = sourceNode.copy() as? SKSpriteNode
            else {
                continue
            }

            layer.removeAllActions()
            layer.zPosition = CGFloat(index + 1)
            addChild(layer)
        }
    }

    private func addFallbackParallaxBackground() {
        gameplayRiverPosition = CGPoint(x: frame.midX, y: frame.midY)
        gameplayRiverSize = size

        for index in 1...5 {
            let layer = SKSpriteNode(imageNamed: "parallax_\(index)")
            configureFullSceneLayer(layer, zPosition: CGFloat(index))
            addChild(layer)
        }
    }

    private func configureRiverLayer(_ node: SKSpriteNode, zPosition: CGFloat) {
        if gameplayRiverSize == .zero {
            configureFullSceneLayer(node, zPosition: zPosition)
            return
        }

        node.size = gameplayRiverSize
        node.position = gameplayRiverPosition
        node.zPosition = zPosition
    }

    private func configureWaveLayer(_ node: SKSpriteNode, zPosition: CGFloat) {
        let textureSize = node.texture?.size() ?? CGSize(width: 1, height: 1)
        let targetHeight = gameplayRiverSize == .zero ? size.height : gameplayRiverSize.height

        node.size = CGSize(
            width: targetHeight * textureSize.width / textureSize.height * 1.085,
            height: targetHeight
        )
        node.position = gameplayRiverSize == .zero
            ? CGPoint(x: frame.midX, y: frame.midY)
            : gameplayRiverPosition
        node.zPosition = zPosition
    }

    private func configureFullSceneLayer(_ node: SKSpriteNode, zPosition: CGFloat) {
        let textureSize = node.texture?.size() ?? size
        let scale = max(size.width / textureSize.width, size.height / textureSize.height)
        node.size = CGSize(
            width: textureSize.width * scale,
            height: textureSize.height * scale
        )
        node.position = CGPoint(x: frame.midX, y: frame.midY)
        node.zPosition = zPosition
    }

    private func addCapybaras() {
        let positions: [CGFloat] = [-0.22, 0, 0.22]
        let sceneScale = min(size.width / 2532, size.height / 1170)
        let gameCapybaraSize = CGSize(
            width: 150.754 * sceneScale,
            height: 149.917 * sceneScale
        )

        for positionMultiplier in positions {
            let capybara = SKSpriteNode(imageNamed: "cap_character")
            capybara.size = gameCapybaraSize
            capybara.position = CGPoint(
                x: frame.midX + size.width * positionMultiplier * 0.2,
                y: frame.minY + size.height * 0.17
            )
            capybara.zPosition = 15
            addChild(capybara)
            capybaraNodes.append(capybara)
        }
    }

    private func configureLog() {
        let sceneScale = min(size.width / 2532, size.height / 1170)
        logNode.size = CGSize(
            width: 404.812 * sceneScale,
            height: 404.812 * sceneScale
        )
        logNode.position = CGPoint(
            x: frame.minX - logNode.frame.width / 2,
            y: frame.minY + size.height * 0.28
        )
        logNode.zPosition = 14
        addChild(logNode)
    }

    private func runStory() {
        run(.sequence([
            .wait(forDuration: 0.8),
            .run { [weak self] in
                self?.bringInWater()
            }
        ]))
    }

    private func bringInWater() {
        guard capybaraNodes.count == 3 else { return }
        
        let audioNode = SKAudioNode(fileNamed: "river_flood.mp3")
        audioNode.autoplayLooped = false
        addChild(audioNode)
        audioNode.run(.changeVolume(to: 0, duration: 0))
        audioNode.run(.play())
        audioNode.run(.changeVolume(to: 1.0, duration: 0.8))
        floodAudioNode = audioNode

        let waterDuration: TimeInterval = 1.65
        let initialLeadingEdgeX = incomingWaterNode.frame.maxX
        let finalPosition = CGPoint(
            x: frame.minX + incomingWaterNode.frame.width / 2,
            y: gameplayRiverPosition.y
        )
        let finalLeadingEdgeX = finalPosition.x + incomingWaterNode.frame.width / 2
        let leadingEdgeTravel = finalLeadingEdgeX - initialLeadingEdgeX

        let waterMove = SKAction.move(
            to: finalPosition,
            duration: waterDuration
        )
        waterMove.timingMode = .linear
        incomingWaterNode.run(waterMove)

        let revealDuration = waterDuration * min(1, size.width / leadingEdgeTravel)
        let revealFullRiver = SKAction.scaleX(to: 1, duration: revealDuration)
        revealFullRiver.timingMode = .linear
        riverRevealMaskNode.run(revealFullRiver)

        let rightmostCapybaraX = capybaraNodes.map(\.position.x).max() ?? frame.midX
        let contactProgress = max(
            0,
            min(1, (rightmostCapybaraX - initialLeadingEdgeX) / leadingEdgeTravel)
        )
        let contactDelay = waterDuration * contactProgress

        run(.sequence([
            .wait(forDuration: contactDelay),
            .run { [weak self] in
                self?.driftTwoCapybaras()
            }
        ]))
    }

    private func driftTwoCapybaras() {
        let driftDuration: TimeInterval = 1.8
        let driftingCapybaras = [capybaraNodes[0], capybaraNodes[2]]

        for (index, capybara) in driftingCapybaras.enumerated() {
            addSpeechText("Help!", above: capybara)

            let drift = SKAction.moveTo(
                x: frame.maxX + capybara.frame.width * CGFloat(index + 1),
                duration: driftDuration
            )
            drift.timingMode = .easeIn
            let sway = SKAction.rotate(
                toAngle: index == 0 ? 0.22 : -0.22,
                duration: driftDuration,
                shortestUnitArc: true
            )

            capybara.run(.sequence([
                .group([drift, sway]),
                .removeFromParent()
            ]))
        }

        run(.sequence([
            .wait(forDuration: driftDuration),
            .run { [weak self] in
                self?.finishRiverTransition()
            }
        ]))
    }

    private func addSpeechText(
        _ text: String,
        above capybara: SKSpriteNode,
        textColor: UIColor = .black
    ) {
        let container = SKNode()
        container.position = CGPoint(x: 0, y: capybara.size.height / 2 + 20)
        container.zPosition = 5

        let fontSize = max(28, min(42, size.width * 0.018))
        let shadow = SKLabelNode(fontNamed: "AvenirNext-Bold")
        shadow.text = text
        shadow.fontSize = fontSize
        shadow.fontColor = .black
        shadow.horizontalAlignmentMode = .center
        shadow.verticalAlignmentMode = .bottom
        shadow.position = CGPoint(x: 2, y: -2)
        container.addChild(shadow)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = fontSize
        label.fontColor = textColor
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .bottom
        container.addChild(label)

        capybara.addChild(container)
    }

    private func finishRiverTransition() {
        shallowRiverNode.removeFromParent()
        incomingWaterNode.run(.sequence([
            .fadeOut(withDuration: 0.2),
            .removeFromParent(),
            .run { [weak self] in
                self?.bringInLog()
            }
        ]))
    }

    private func bringInLog() {
        let destination = CGPoint(
            x: frame.midX,
            y: frame.minY + size.height * 0.28
        )
        let move = SKAction.move(to: destination, duration: 1.15)
        move.timingMode = .easeOut

        logNode.run(.sequence([
            move,
            .wait(forDuration: 0.25),
            .run { [weak self] in
                self?.jumpLastCapybaraOntoLog()
            }
        ]))
    }

    private func jumpLastCapybaraOntoLog() {
        guard let capybara = capybaraNodes[safe: 1] else { return }

        let landingPosition = CGPoint(
            x: logNode.position.x,
            y: logNode.position.y + size.height * 0.035
        )
        let jumpPeak = CGPoint(
            x: (capybara.position.x + landingPosition.x) / 2,
            y: max(capybara.position.y, landingPosition.y) + size.height * 0.10
        )

        let jumpUp = SKAction.move(to: jumpPeak, duration: 0.42)
        jumpUp.timingMode = .easeOut
        let land = SKAction.move(to: landingPosition, duration: 0.42)
        land.timingMode = .easeIn

        capybara.run(.sequence([
            jumpUp,
            land,
            .run { [weak self, weak capybara] in
                guard let self, let capybara else { return }
                self.addSpeechText(
                    "I’ll save you both!",
                    above: capybara,
                    textColor: .black
                )
                self.floodAudioNode?.run(.changeVolume(to: 0, duration: 1.4))
            },
            .wait(forDuration: 1.4),
            .run { [weak self] in
                self?.startGame()
            }
        ]))
    }

    private func startGame() {
        guard
            let gameScene = SKScene(fileNamed: "GameScene") as? GameScene,
            let survivingCapybara = capybaraNodes[safe: 1]
        else {
            return
        }

        gameScene.scaleMode = .aspectFill
        let woodPosition = mapPosition(logNode.position, to: gameScene)
        let capybaraPosition = mapPosition(survivingCapybara.position, to: gameScene)
        gameScene.configureStoryStart(
            woodPosition: woodPosition,
            capybaraPosition: capybaraPosition
        )

        let transition = SKTransition.crossFade(withDuration: 1.0)
        view?.presentScene(gameScene, transition: transition)
    }

    private func mapPosition(_ position: CGPoint, to scene: SKScene) -> CGPoint {
        let horizontalProgress = (position.x - frame.minX) / size.width
        let verticalProgress = (position.y - frame.minY) / size.height

        return CGPoint(
            x: scene.frame.minX + scene.size.width * horizontalProgress,
            y: scene.frame.minY + scene.size.height * verticalProgress
        )
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
