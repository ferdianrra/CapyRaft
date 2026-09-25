//
//  HowToPlayScene.swift
//  capfight
//
//  Created by Sendi Setiawan on 25/09/26.
//

import SpriteKit
import UIKit

final class HowToPlayScene: SKScene {
    private struct Instruction {
        let imageName: String
        let title: String
        let description: String
    }

    private let instructions = [
        Instruction(
            imageName: "how-to-play/switch-lanes",
            title: "MOVE YOUR CAPYBARAS",
            description: "Move your capybaras using analog controller."
        ),
        Instruction(
            imageName: "how-to-play/avoid-rocks",
            title: "AVOID ROCKS",
            description: "Rocks stay in place. Switch lanes to dodge them. Hitting a rock costs one capybara."
        ),
        Instruction(
            imageName: "how-to-play/avoid-snakes",
            title: "AVOID SNAKES",
            description: "Snakes can strike without warning. Move to another lane quickly!"
        ),
        Instruction(
            imageName: "how-to-play/fight-back",
            title: "FIGHT BACK",
            description: "Attack snakes by throwing a rock before they strike."
        ),
        Instruction(
            imageName: "how-to-play/protect-your-capybara",
            title: "PROTECT YOUR CAPYBARA",
            description: "Start with 1 capybara. Rescue more to stay in the game."
        ),
        Instruction(
            imageName: "how-to-play/rescue-capybara",
            title: "RESCUE CAPYBARA",
            description: "Reach drifting capybaras to rescue them. They’ll climb onto your log and join you."
        )
    ]

    override func didMove(to view: SKView) {
        backgroundColor = .black
        buildInterface()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard view != nil else { return }
        buildInterface()
    }

    private func buildInterface() {
        removeAllChildren()

        let menuBackground = SKSpriteNode(imageNamed: "main_menu_background")
        let menuTextureSize = menuBackground.texture?.size() ?? size
        let menuBackgroundScale = max(
            size.width / menuTextureSize.width,
            size.height / menuTextureSize.height
        )
        menuBackground.size = CGSize(
            width: menuTextureSize.width * menuBackgroundScale,
            height: menuTextureSize.height * menuBackgroundScale
        )
        menuBackground.position = CGPoint(x: frame.midX, y: frame.midY)
        menuBackground.zPosition = -2
        addChild(menuBackground)

        let background = SKSpriteNode(imageNamed: "how-to-play/bg")
        let textureSize = background.texture?.size() ?? size
        let maximumPanelSize = CGSize(width: size.width * 0.88, height: size.height * 0.84)
        let backgroundScale = min(
            maximumPanelSize.width / textureSize.width,
            maximumPanelSize.height / textureSize.height
        )
        background.size = CGSize(
            width: textureSize.width * backgroundScale,
            height: textureSize.height * backgroundScale
        )
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        background.zPosition = -1
        addChild(background)

        let panelFrame = CGRect(
            x: background.position.x - background.size.width / 2,
            y: background.position.y - background.size.height / 2,
            width: background.size.width,
            height: background.size.height
        )

        let closeButton = SKSpriteNode(imageNamed: "how-to-play/close-button")
        closeButton.name = "closeButton"
        closeButton.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        let closeButtonSide = max(100, min(144, size.width * 0.13))
        closeButton.size = CGSize(width: closeButtonSide, height: closeButtonSide)
        closeButton.position = CGPoint(
            x: background.size.width / 2.075,
            y: background.size.height / 2.15
        )
        closeButton.zPosition = 11
        background.addChild(closeButton)

        let heading = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        heading.text = "How To Play"
        heading.fontSize = max(64, min(42, size.width * 0.031))
        heading.fontColor = UIColor(red: 0.20, green: 0.12, blue: 0.07, alpha: 1)
        heading.horizontalAlignmentMode = .center
        heading.verticalAlignmentMode = .center
        heading.position = CGPoint(x: panelFrame.midX, y: panelFrame.maxY - panelFrame.height * 0.1)
        heading.zPosition = 2
        addChild(heading)

        let horizontalMargin = panelFrame.width * 0.07
        let topMargin = panelFrame.height * 0.17
        let bottomMargin = panelFrame.height * 0.07
        let columnGap = panelFrame.width * 0.045
        let rowGap = panelFrame.height * 0.025
        let cellWidth = (panelFrame.width - (horizontalMargin * 2) - columnGap) / 2
        let cellHeight = (panelFrame.height - topMargin - bottomMargin - (rowGap * 2)) / 3

        for (index, instruction) in instructions.enumerated() {
            let column = index % 2
            let row = index / 2
            let centerX = panelFrame.minX + horizontalMargin + (cellWidth / 2)
                + CGFloat(column) * (cellWidth + columnGap)
            let centerY = panelFrame.maxY - topMargin - (cellHeight / 2)
                - CGFloat(row) * (cellHeight + rowGap)

            addInstruction(
                instruction,
                at: CGPoint(x: centerX, y: centerY),
                cellWidth: cellWidth,
                cellHeight: cellHeight
            )
        }
    }

    private func addInstruction(
        _ instruction: Instruction,
        at center: CGPoint,
        cellWidth: CGFloat,
        cellHeight: CGFloat
    ) {
        let container = SKNode()
        container.position = center
        addChild(container)

        let image = SKSpriteNode(imageNamed: instruction.imageName)
        let imageWidth = min(cellWidth * 0.42, cellHeight * 1.05)
        let sourceSize = image.texture?.size() ?? CGSize(width: 1, height: 1)
        let imageHeight = imageWidth * sourceSize.height / sourceSize.width
        image.size = CGSize(width: imageWidth, height: min(imageHeight, cellHeight * 0.9))
        image.position = CGPoint(x: -cellWidth / 2 + image.size.width / 2, y: 0)
        container.addChild(image)

        let textLeading = image.position.x + image.size.width / 2 + cellWidth * 0.045
        let textWidth = cellWidth / 2 - textLeading
        let titleFontSize = max(32, min(38, size.width * 0.034))
        let bodyFontSize = max(28, min(32, size.width * 0.024))

        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = instruction.title
        title.fontSize = titleFontSize
        title.fontColor = UIColor(red: 0.20, green: 0.12, blue: 0.07, alpha: 1)
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .top
        title.position = CGPoint(x: textLeading, y: cellHeight * 0.35)
        container.addChild(title)

        let description = SKLabelNode(fontNamed: "AvenirNext-Medium")
        description.text = instruction.description
        description.fontSize = bodyFontSize
        description.fontColor = UIColor(red: 0.27, green: 0.18, blue: 0.10, alpha: 1)
        description.horizontalAlignmentMode = .left
        description.verticalAlignmentMode = .top
        description.numberOfLines = 0
        description.preferredMaxLayoutWidth = textWidth
        description.position = CGPoint(x: textLeading, y: title.position.y - titleFontSize * 1.45)
        container.addChild(description)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard
            let touch = touches.first,
            nodeOrParentNamed("closeButton", at: touch.location(in: self)) != nil,
            let menuScene = SKScene(fileNamed: "MainMenuScene")
        else {
            return
        }

        menuScene.scaleMode = .aspectFill
        view?.presentScene(menuScene, transition: .fade(withDuration: 0.25))
    }

    private func nodeOrParentNamed(_ name: String, at point: CGPoint) -> SKNode? {
        var node: SKNode? = atPoint(point)
        while let currentNode = node {
            if currentNode.name == name {
                return currentNode
            }
            node = currentNode.parent
        }
        return nil
    }
}
