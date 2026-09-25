import SpriteKit

/// ViewModel to manage game state, score, timers, and game progression
final class GameViewModel {
    
    // MARK: - Published / State Properties
    private(set) var score: Int = 0
    private(set) var scoreTimer: TimeInterval = 0
    
    var isGameOverTriggered: Bool = false
    var isRecovering: Bool = false
    
    // MARK: - Computed Properties
    var difficultyMultiplier: Double {
        // Perlambat laju kenaikan difficulty agar tidak langsung "ngebut" di awal
        return 1.0 + (Double(score) / 1000.0)
    }
    
    var riverSpeed: CGFloat {
        return CGFloat(2.0 * difficultyMultiplier)
    }
    
    var forestSpeed: CGFloat {
        return 0.5
    }
    
    var obstacleSpeed: CGFloat {
        return CGFloat(2.0 * difficultyMultiplier)
    }
    
    var snakeSpeed: CGFloat {
        return CGFloat(2.0 * difficultyMultiplier)
    }
    
    var woodBackwardSpeed: CGFloat {
        return CGFloat(-3.0 * difficultyMultiplier)
    }
    
    // MARK: - Game State Management
    func reset() {
        score = 0
        scoreTimer = 0
        isGameOverTriggered = false
        isRecovering = false
    }
    
    func updateScore(deltaTime: TimeInterval, onScoreChange: (Int) -> Void) {
        guard !isGameOverTriggered else { return }
        
        // Kecepatan timer bergantung pada seberapa cepat sungai mengalir (difficultyMultiplier)
        scoreTimer += deltaTime * difficultyMultiplier
        
        // Skor bertambah 1 setiap 0.1 detik (base rate = 10 skor / detik)
        if scoreTimer >= 0.1 {
            score += 1
            onScoreChange(score)
            scoreTimer = 0
        }
    }
    
    func saveHighScoreIfNeeded() {
        let currentBest = UserDefaults.standard.integer(forKey: "BestScore")
        if score > currentBest {
            UserDefaults.standard.set(score, forKey: "BestScore")
        }
    }
    
//    func triggerGameOver(in scene: SKScene) {
//        guard !isGameOverTriggered else { return }
//        isGameOverTriggered = true
//        saveHighScoreIfNeeded()
//        
//        let waitAndGo = SKAction.sequence([
//            SKAction.wait(forDuration: 1.0),
//            SKAction.run {
//                if let menuScene = SKScene(fileNamed: "MainMenuScene") {
//                    menuScene.scaleMode = .aspectFill
//                    let transition = SKTransition.fade(withDuration: 0.8)
//                    scene.view?.presentScene(menuScene, transition: transition)
//                }
//            }
//        ])
//        scene.run(waitAndGo)
//    }
    
    func triggerGameOver(in scene: GameScene) {
        guard !isGameOverTriggered else { return }

        isGameOverTriggered = true
        saveHighScoreIfNeeded()
        scene.showGameOver()
    }
}
