import SpriteKit
import UIKit

final class JoystickNode: SKNode {
    
    // MARK: - Properties
    private var baseNode: SKShapeNode!
    private var knobNode: SKShapeNode!
    
    private(set) var isActive = false
    private(set) var activeTouch: UITouch?
    private(set) var velocity = CGVector.zero
    
    let baseRadius: CGFloat = 120.0
    private let knobRadius: CGFloat = 60.0
    
    func setup(sceneSize: CGSize) {
        baseNode = SKShapeNode(circleOfRadius: baseRadius)
        baseNode.strokeColor = .white
        baseNode.lineWidth = 5
        baseNode.alpha = 0.6
        baseNode.position = CGPoint(x: -sceneSize.width / 2 + 220, y: -sceneSize.height / 2 + 220)
        baseNode.zPosition = 90
        addChild(baseNode)
        
        knobNode = SKShapeNode(circleOfRadius: knobRadius)
        knobNode.fillColor = .white
        knobNode.position = baseNode.position
        knobNode.zPosition = 91
        addChild(knobNode)
    }
    

    func handleTouchBegan(_ touch: UITouch, location: CGPoint) -> Bool {
        if baseNode.contains(location) && activeTouch == nil {
            isActive = true
            activeTouch = touch
            return true
        }
        return false
    }
    
    func handleTouchMoved(_ touch: UITouch, location: CGPoint) {
        guard isActive, touch == activeTouch else { return }
        
        let dx = location.x - baseNode.position.x
        let dy = location.y - baseNode.position.y
        let distance = hypot(dx, dy)
        let angle = atan2(dy, dx)
        
        let constrainedDistance = min(distance, baseRadius)
        let knobX = constrainedDistance * cos(angle)
        let knobY = constrainedDistance * sin(angle)
        
        knobNode.position = CGPoint(x: baseNode.position.x + knobX, y: baseNode.position.y + knobY)
        velocity = CGVector(dx: knobX / baseRadius, dy: knobY / baseRadius)
    }
    
    func handleTouchEnded(_ touch: UITouch) {
        guard touch == activeTouch else { return }
        
        isActive = false
        activeTouch = nil
        
        let resetKnob = SKAction.move(to: baseNode.position, duration: 0.15)
        resetKnob.timingMode = .easeOut
        knobNode.run(resetKnob)
        velocity = .zero
    }
    
    func resetVelocity() {
        velocity = .zero
    }
}
