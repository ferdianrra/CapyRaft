import SpriteKit

final class StoryScene: SKScene {
    private let shallowRiverNode = SKSpriteNode(imageNamed: "story/sungai-dangkal")
    private let fullRiverNode = SKSpriteNode(imageNamed: "story/sungai-penuh")
    private let incomingWaterNode = SKSpriteNode(imageNamed: "story/air-sungai")
    private let logNode = SKSpriteNode(imageNamed: "wood")
    private var capybaraNodes: [SKSpriteNode] = []

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

        configureFullSceneLayer(shallowRiverNode, zPosition: 10)
        addChild(shallowRiverNode)

        configureFullSceneLayer(fullRiverNode, zPosition: 11)
        fullRiverNode.alpha = 0
        addChild(fullRiverNode)

        configureFullSceneLayer(incomingWaterNode, zPosition: 12)
        incomingWaterNode.position.x = frame.minX - incomingWaterNode.size.width / 2
        addChild(incomingWaterNode)

        addCapybaras()
        configureLog()
    }

    private func addParallaxBackground() {
        for index in 1...5 {
            let layer = SKSpriteNode(imageNamed: "parallax_\(index)")
            configureFullSceneLayer(layer, zPosition: CGFloat(index))
            layer.position.y += size.height * 0.60
            addChild(layer)
        }
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
                x: frame.midX + size.width * positionMultiplier,
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

        let waterMove = SKAction.move(
            to: CGPoint(x: frame.midX, y: frame.midY),
            duration: 1.65
        )
        waterMove.timingMode = .easeInEaseOut
        incomingWaterNode.run(waterMove)

        let driftingCapybaras = [capybaraNodes[0], capybaraNodes[2]]
        for (index, capybara) in driftingCapybaras.enumerated() {
            let drift = SKAction.moveTo(
                x: frame.maxX + capybara.frame.width * CGFloat(index + 1),
                duration: 1.8
            )
            drift.timingMode = .easeIn
            let sway = SKAction.rotate(
                toAngle: index == 0 ? 0.22 : -0.22,
                duration: 1.8,
                shortestUnitArc: true
            )

            capybara.run(.sequence([
                .group([drift, sway]),
                .removeFromParent()
            ]))
        }

        run(.sequence([
            .wait(forDuration: 1.65),
            .run { [weak self] in
                self?.finishRiverTransition()
            }
        ]))
    }

    private func finishRiverTransition() {
        fullRiverNode.run(.fadeIn(withDuration: 0.25))
        shallowRiverNode.run(.fadeOut(withDuration: 0.25))
        incomingWaterNode.run(.sequence([
            .fadeOut(withDuration: 0.25),
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
            .wait(forDuration: 0.55),
            .run { [weak self] in
                self?.startGame()
            }
        ]))
    }

    private func startGame() {
        guard let gameScene = SKScene(fileNamed: "GameScene") else { return }

        gameScene.scaleMode = .aspectFill
        view?.presentScene(gameScene, transition: .fade(withDuration: 0.65))
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
