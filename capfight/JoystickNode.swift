import SpriteKit
import UIKit

final class JoystickNode: SKNode {
    
    // MARK: - Properties
    private var baseNode: SKSpriteNode!
    private var knobNode: SKSpriteNode!

    private(set) var isActive = false
    private(set) var activeTouch: UITouch?
    private(set) var velocity = CGVector.zero
    let baseRadius: CGFloat = 190.0
    private let knobRadius: CGFloat = 90.0
    func setup(sceneSize: CGSize) {
        guard let image = UIImage(named: "joystick_control"),
              let cgImage = image.cgImage else { return }

        // Ambil bagian tengah asset untuk knob yang bergerak.
        let side = CGFloat(cgImage.width) * 0.44
        let cropRect = CGRect(
            x: (CGFloat(cgImage.width) - side) / 2,
            y: (CGFloat(cgImage.height) - side) / 2,
            width: side,
            height: side
        )
        guard let cropped = cgImage.cropping(to: cropRect) else { return }
        let knobImage = UIImage(cgImage: cropped)

        // Ambil ring dari asset yang sama, lalu kosongkan bagian tengahnya.
        let renderer = UIGraphicsImageRenderer(size: image.size)
        let ringImage = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: image.size))
            context.cgContext.setBlendMode(.clear)

            let radius = image.size.width * 0.27
            context.cgContext.fillEllipse(in: CGRect(
                x: image.size.width / 2 - radius,
                y: image.size.height / 2 - radius,
                width: radius * 2,
                height: radius * 2
            ))
        }

        baseNode = SKSpriteNode(texture: SKTexture(image: ringImage))
        baseNode.size = CGSize(
            width: baseRadius * 2,
            height: baseRadius * 2
        )
        baseNode.position = CGPoint(
            x: -sceneSize.width / 2 + 230,
            y: -sceneSize.height / 2 + 230
        )
        baseNode.zPosition = 90
        addChild(baseNode)

        knobNode = SKSpriteNode(texture: SKTexture(image: knobImage))
        knobNode.size = CGSize(
            width: knobRadius * 2,
            height: knobRadius * 2
        )
        knobNode.position = baseNode.position
        knobNode.zPosition = 91
        addChild(knobNode)
    }

    func handleTouchBegan(_ touch: UITouch, location: CGPoint) -> Bool {
        guard let baseNode, let knobNode, activeTouch == nil else {
            return false
        }

        let distance = hypot(
            location.x - baseNode.position.x,
            location.y - baseNode.position.y
        )

        guard distance <= baseRadius else { return false }

        knobNode.removeAllActions()
        isActive = true
        activeTouch = touch
        return true
    }

    func handleTouchMoved(_ touch: UITouch, location: CGPoint) {
        guard isActive, touch == activeTouch else { return }

        let dx = location.x - baseNode.position.x
        let dy = location.y - baseNode.position.y
        let distance = hypot(dx, dy)
        let angle = atan2(dy, dx)

        // Biar knob putih tidak keluar dari ring.
        let travelRadius = baseRadius - knobRadius
        let constrainedDistance = min(distance, travelRadius)
        let knobX = constrainedDistance * cos(angle)
        let knobY = constrainedDistance * sin(angle)

        knobNode.position = CGPoint(
            x: baseNode.position.x + knobX,
            y: baseNode.position.y + knobY
        )
        velocity = CGVector(
            dx: knobX / travelRadius,
            dy: knobY / travelRadius
        )
    }

    func handleTouchEnded(_ touch: UITouch) {
        guard touch == activeTouch else { return }

        isActive = false
        activeTouch = nil
        velocity = .zero

        let resetKnob = SKAction.move(to: baseNode.position, duration: 0.15)
        resetKnob.timingMode = .easeOut
        knobNode.run(resetKnob)
    }
    
    func resetTouch() {
        isActive = false
        activeTouch = nil
        velocity = .zero

        knobNode.removeAllActions()
        knobNode.position = baseNode.position
    }

    func resetVelocity() {
        velocity = .zero
    }
}
