import SpriteKit

class MainMenuScene: SKScene {
    
    var bestScoreLabel: SKLabelNode?
    private var bgMusicNode: SKAudioNode?
    private var isTransitioning = false
    
    override func didMove(to view: SKView) {
        isTransitioning = false
        bestScoreLabel = self.childNode(withName: "//bestScoreLabel") as? SKLabelNode
        
        let highscore = UserDefaults.standard.integer(forKey: "BestScore")
        bestScoreLabel?.text = "Best Score: \(highscore)"
        
        setupBackgroundMusic()
    }
    
    private func setupBackgroundMusic() {
        if bgMusicNode == nil {
            let musicURL: URL? = Bundle.main.url(forResource: "main_theme", withExtension: "wav") ??
                                 Bundle.main.url(forResource: "main_theme", withExtension: "wav", subdirectory: "sound")
            if let url = musicURL {
                let node = SKAudioNode(url: url)
                node.autoplayLooped = true
                addChild(node)
                bgMusicNode = node
            } else {
                let node = SKAudioNode(fileNamed: "main_theme.wav")
                node.autoplayLooped = true
                addChild(node)
                bgMusicNode = node
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        isTransitioning = true
        
        bgMusicNode?.run(SKAction.stop())
        bgMusicNode?.removeFromParent()
        
        if let gameScene = SKScene(fileNamed: "GameScene") {
            gameScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 0.5)
            self.view?.presentScene(gameScene, transition: transition)
        }
    }
}
