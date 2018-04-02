//
//  ViewController.swift
//  Breakdown
//
//  Created by Lukas Mueller on 03.04.18.
//  Copyright © 2018 Lukas A. Mueller. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

public enum GameColor {
    case purple
    case red
    case orange
    case yellow
    case green
    case blue
    case pink
}

public extension GameColor {
    public var getColor: UIColor {
        switch self {
        case .purple: return UIColor(red:0.82, green:0.18, blue:0.83, alpha:1.0)
        case .red:    return UIColor(red:0.98, green:0.32, blue:0.30, alpha:1.0)
        case .orange: return UIColor(red:1.00, green:0.50, blue:0.00, alpha:1.0)
        case .yellow: return UIColor(red:1.00, green:0.56, blue:0.00, alpha:1.0)
        case .green:  return UIColor(red:0.00, green:0.71, blue:0.02, alpha:1.0)
        case .blue:   return UIColor(red:0.42, green:0.37, blue:0.98, alpha:1.0)
        case .pink:   return UIColor(red:0.81, green:0.20, blue:0.80, alpha:1.0)
        }
    }
    
    public var getImpulseMultiplicator: CGFloat {
        switch self {
        case .purple: return 4
        case .red:    return 3.5
        case .orange: return 3
        case .yellow: return 2.5
        case .green:  return 2
        case .blue:   return 1.5
        case .pink:   return 1
        }
    }
    
}

public class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let blockIdentifier: UInt32 = 0x1 << 0
    let ballIdentifier:  UInt32 = 0x1 << 1
    
    var bat:  SKSpriteNode? = nil
    var ball: SKSpriteNode? = nil
    
    var points: Int = 0 {
        didSet{
            print(points)
        }
    }
    
    var audioPlayer: AVAudioPlayer?
    let hitsBatSound = URL(fileURLWithPath: Bundle.main.path(forResource: "hits_bat", ofType: "wav")!)
    let hitsBlockSound = URL(fileURLWithPath: Bundle.main.path(forResource: "hits_block", ofType: "wav")!)
    
    public override func didMove(to view: SKView) {
        self.backgroundColor = .black
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector.zero
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody!.friction = 0.0
        
        let areaSize = self.frame.size
        
        addBlocksOfColors(area: CGRect(
            x: 0,
            y: areaSize.height * 0.6,
            width: areaSize.width,
            height: areaSize.height * 0.15
        ))
        
        // Ball Setup
        
        ball = SKSpriteNode(
            color: GameColor.pink.getColor,
            size: CGSize(
                width: 15,
                height: 15
            )
        )
        
        ball!.position = CGPoint(
            x: 200,
            y: 200
        )
        
        ball!.physicsBody = SKPhysicsBody(rectangleOf: ball!.size)
        ball!.physicsBody!.contactTestBitMask = ballIdentifier
        //        ball!.physicsBody!.isDynamic = false
        ball!.name = "Ball"
        ball!.physicsBody!.allowsRotation = false
        ball!.physicsBody!.friction = 0.0
        ball!.physicsBody!.restitution = 1.0
        ball!.physicsBody!.linearDamping = 0.0
        
        // Bat Setup
        
        bat = SKSpriteNode(
            color: GameColor.pink.getColor,
            size: CGSize(
                width: 0.2 * self.frame.width,
                height: 0.025 * self.frame.height
            )
        )
        
        bat!.position = CGPoint(
            x: self.frame.width/2,
            y: 0.2 * self.frame.height
        )
        
        bat!.name = "Bat"
        bat!.physicsBody = SKPhysicsBody(rectangleOf: bat!.size)
        bat!.physicsBody!.allowsRotation = false
        bat!.physicsBody!.isDynamic = false
        // Add
        bat!.physicsBody!.friction = 0.0
        
        addChild(bat!)
        addChild(ball!)
        
        ball!.physicsBody!.applyImpulse(CGVector(dx: 2, dy: 3))
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let loc = touches.first!.location(in: self)
        
        //        ball!.position = loc
        
        
        // Ensure that bat doesn't move out of screen
        let min = loc.x - bat!.frame.width/2
        let max = bat!.frame.width + loc.x
        
        bat!.position.x = loc.x
        
        //        if min >= 0 && max <= self.frame.width {
        //            // Update Pos of bat
        //            bat!.position.x = loc.x
        //        }
    }
    
    public func didBegin(_ contact: SKPhysicsContact) {
        //        print("Hi")
        
        if let nameA = contact.bodyA.node?.name, let nameB = contact.bodyB.node?.name {
            
            // Collision Ball & Block
            if nameA == "Block" && nameB == "Ball" {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: hitsBlockSound)
                    audioPlayer?.play()
                } catch {
                    print("Couldn't play!")
                }
                contact.bodyA.node!.removeFromParent()
                self.points += 1
                //                contact.bodyB.node!.physicsBody!.applyImpulse(CGVector(dx: 2, dy: -1))
            }
            
            if nameA == "Bat" && nameB == "Ball" {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: hitsBatSound)
                    audioPlayer?.play()
                } catch {
                    print("Couldn't play!")
                }
            }
        }
        
    }
    
    // Additional Functions
    
    public func addBlocksOfColors(area: CGRect) {
        let colors: Array<GameColor> = [.blue, .green, .yellow, .orange, .red, .purple]
        let height = area.size.height / CGFloat(colors.count)
        
        colors.enumerated().forEach {
            addBlocks(
                ofColor: $0.element,
                atHeight: CGFloat($0.offset) * height + area.origin.y,
                withAmount: 20,
                andHeight: height
            )
        }
    }
    
    public func addBlocks(ofColor color: GameColor, atHeight heightPos: CGFloat, withAmount number: Int, andHeight height: CGFloat) {
        let widthPerBlock = self.frame.width / CGFloat(number)
        
        (0...number).forEach {
            
            let block = SKSpriteNode(
                color: color.getColor,
                size: CGSize(
                    width: widthPerBlock,
                    height: height
                )
            )
            
            block.position = CGPoint(
                x: CGFloat($0) * widthPerBlock,
                y: heightPos
            )
            
            block.physicsBody = SKPhysicsBody(rectangleOf: CGSize(
                width: widthPerBlock,
                height: height
            ))
            
            block.physicsBody!.isDynamic = false
            
            block.physicsBody!.contactTestBitMask = blockIdentifier
            block.name = "Block"
            block.physicsBody!.friction = 0.0
            self.addChild(block)
        }
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let sceneView = SKView(frame: view.frame)
        
        let scene = GameScene(size: view.frame.size)
        sceneView.presentScene(scene)
        view.addSubview(sceneView)
        
    }


}

