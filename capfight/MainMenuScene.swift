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
        
        // Note: You must call this here so the button actually gets named before touches begin
        nameHowToPlayButton()
        setupBackgroundMusic()
    }
    
    private func nameHowToPlayButton() {
        let howToTextureSize = SKTexture(imageNamed: "how_to_play_texture").size()
        
        enumerateChildNodes(withName: "//*") { node, _ in
            guard let sprite = node as? SKSpriteNode,
                  let textureSize = sprite.texture?.size(),
                  abs(textureSize.width - howToTextureSize.width) < 0.5,
                  abs(textureSize.height - howToTextureSize.height) < 0.5 else {
                return
            }
            
            sprite.name = "howToPlayButton"
        }
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
    
    // Extracted music cleanup into a helper function to avoid code duplication
    private func stopBackgroundMusic() {
        bgMusicNode?.run(SKAction.stop())
        bgMusicNode?.removeFromParent()
        bgMusicNode = nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 1. Prevent touches if a transition is already in progress
        guard !isTransitioning else { return }
        
        // 2. Grab the first touch
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = self.atPoint(location)
        
        // 3. Check for the How To Play button first
        if touchedNode.name == "howToPlayButton" {
            isTransitioning = true
            
            let howToPlayScene = HowToPlayScene(size: size)
            howToPlayScene.anchorPoint = anchorPoint
            howToPlayScene.scaleMode = scaleMode
            let transition = SKTransition.fade(withDuration: 0.25)
            self.view?.presentScene(howToPlayScene, transition: transition)
            
        } else {
            // 4. Any other touch triggers the Play transition
            isTransitioning = true
            
            stopBackgroundMusic()
            
            if let gameScene = SKScene(fileNamed: "GameScene") {
                gameScene.scaleMode = .aspectFill
                let transition = SKTransition.fade(withDuration: 0.5)
                self.view?.presentScene(gameScene, transition: transition)
            }
        }
    }

}
