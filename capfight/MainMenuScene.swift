//
//  MainMenuScene.swift
//  capfight
//
//  Created by Ferdiansyah Annora on 24/09/26.
//

import SpriteKit

class MainMenuScene: SKScene {
    
    var bestScoreLabel: SKLabelNode?
    
    override func didMove(to view: SKView) {
        bestScoreLabel = self.childNode(withName: "//bestScoreLabel") as? SKLabelNode
        
        let highscore = UserDefaults.standard.integer(forKey: "BestScore")
        bestScoreLabel?.text = "Best Score: \(highscore)"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNode = self.atPoint(location)
            
            if touchedNode.name == "playButton" {
                if let gameScene = SKScene(fileNamed: "GameScene") {
                    gameScene.scaleMode = .aspectFill
                    let transition = SKTransition.fade(withDuration: 0.5)
                    self.view?.presentScene(gameScene, transition: transition)
                }
            }
        }
    }
}
