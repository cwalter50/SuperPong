//
//  GameScene.swift
//  PongSuper
//
//  Created by Christopher Walter on 12/11/17.
//  Copyright © 2017 AssistStat. All rights reserved.
//

import SpriteKit
import GameplayKit

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let ball: UInt32 = 0b1 // 000000000000000000000000000001
    static let topOrBottom: UInt32 = 0b10 // 000000000000000000000000000010
    static let paddle: UInt32 = 0b100 // 000000000000000000000000000100
    static let aiPaddle: UInt32 = 0b1000 // 00000000000000000000000001000
}

class GameScene: SKScene, SKPhysicsContactDelegate{
    
    var myPaddle = SKSpriteNode()
    var ball = SKSpriteNode()
    var aiPaddle = SKSpriteNode()
    var bottom = SKSpriteNode()
    var top = SKSpriteNode()
    var playerScoreLabel = SKLabelNode()
    var computerScoreLabel = SKLabelNode()
    static var playerScore = 0
    static var computerScore = 0
    
    
    override func didMove(to view: SKView) {
        GameScene.playerScore = 0
        GameScene.computerScore = 0
        
        // Set the border of the world to the frame
        let borderBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0.0
        physicsBody = borderBody
        
        physicsWorld.gravity = CGVector.zero
        
        // get access to paddle.
        myPaddle = childNode(withName: "paddle") as! SKSpriteNode
        ball = childNode(withName: "ball") as! SKSpriteNode
        bottom = childNode(withName: "bottom") as! SKSpriteNode
        top = childNode(withName: "top") as! SKSpriteNode

        createAIPaddle()
        createLabels()
        
        ball.physicsBody?.categoryBitMask = PhysicsCategory.ball
        myPaddle.physicsBody?.categoryBitMask = PhysicsCategory.paddle
        top.physicsBody?.categoryBitMask = PhysicsCategory.topOrBottom
        bottom.physicsBody?.categoryBitMask = PhysicsCategory.topOrBottom
        aiPaddle.physicsBody?.categoryBitMask = PhysicsCategory.aiPaddle
        
        
        ball.physicsBody?.contactTestBitMask = PhysicsCategory.topOrBottom
        physicsWorld.contactDelegate = self
    
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if (contact.bodyA.categoryBitMask == PhysicsCategory.ball && contact.bodyB.categoryBitMask == PhysicsCategory.topOrBottom) || (contact.bodyB.categoryBitMask == PhysicsCategory.ball && contact.bodyA.categoryBitMask == PhysicsCategory.topOrBottom) {
            print("ball hit top or bottom")
            
            if contact.bodyB.node == top || contact.bodyA.node == top {
                GameScene.playerScore += 1
                playerScoreLabel.text = String(GameScene.playerScore)
            } else {
                GameScene.computerScore += 1
                computerScoreLabel.text = String(GameScene.computerScore)
            }
            
            if GameScene.playerScore == 2 {
                let gameOverScene = GameOverScene(size: self.size)
                let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
                view?.presentScene(gameOverScene, transition: reveal)
                
            }
            
            if GameScene.computerScore == 2 {
                // present gameOverScene
                let gameOverScene = GameOverScene(size: self.size)
                let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
                view?.presentScene(gameOverScene, transition: reveal)
            }
            restartBall()
        }
    }
    
    func restartBall() {
        // stop the ball
        ball.physicsBody!.velocity = CGVector.zero
        // wait 1 second
        let wait = SKAction.wait(forDuration: 1.0)
    
        // move to center
        let moveBall = SKAction.run {
            self.ball.position = CGPoint(x: self.frame.width * 0.5, y: self.frame.height * 0.5)
        }
        let pushBall = SKAction.run {
            // push ball again
            let array = [150, 200, 100, -150, -200, -100]
            let randx = Int(arc4random_uniform(UInt32(array.count)))
            let randy = Int(arc4random_uniform(UInt32(array.count)))
            self.ball.physicsBody!.applyImpulse(CGVector(dx: array[randx], dy: array[randy]))
        }
        
        let sequence = SKAction.sequence([wait, moveBall, wait, pushBall])
        
        run(sequence)
    }
    
    
    
    func createLabels() {
        playerScoreLabel = SKLabelNode(fontNamed: "Arial")
        playerScoreLabel.text = "0"
        playerScoreLabel.fontSize = 75
        playerScoreLabel.position = CGPoint(x: frame.width * 0.25, y: frame.height * 0.10)
        playerScoreLabel.fontColor = UIColor.white
        addChild(playerScoreLabel)
      
        computerScoreLabel = SKLabelNode(fontNamed: "Arial")
        computerScoreLabel.text = "0"
        computerScoreLabel.fontSize = 75
        computerScoreLabel.position = CGPoint(x: frame.width * 0.75, y: frame.height * 0.90)
        computerScoreLabel.fontColor = UIColor.white
        addChild(computerScoreLabel)
  
    }
    func createAIPaddle() {
        
        let size = myPaddle.size
        aiPaddle = SKSpriteNode(color: UIColor.orange, size: CGSize(width: 200, height: 50))
        aiPaddle.position = CGPoint(x: frame.width / 2, y: frame.height * 0.8)
        
        aiPaddle.physicsBody = SKPhysicsBody(rectangleOf: aiPaddle.frame.size)
        
        aiPaddle.physicsBody?.affectedByGravity = false
        aiPaddle.physicsBody?.allowsRotation = false
        aiPaddle.physicsBody?.friction = 0
        aiPaddle.physicsBody?.isDynamic = false
        
        aiPaddle.name = "aiPaddle"
        addChild(aiPaddle)
        
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run(followBall), SKAction.wait(forDuration: 0.4)])
        ))
    
    }
    func followBall() {
        let move = SKAction.moveTo(x: ball.position.x, duration: 0.4)
        aiPaddle.run(move)
    }
    
    var isFingerOnPaddle = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //  if touch is on paddle... turn bool to true
        let touch = touches.first
        let touchLocation = touch!.location(in: self)
        
        if let body = physicsWorld.body(at: touchLocation) {
            if body.node?.name == "paddle" {
                print("we found the paddle")
                isFingerOnPaddle = true
            }
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // if bool is true, move paddle
        if isFingerOnPaddle == true {
            let touch = touches.first
            let touchLocation = touch!.location(in: self)
            myPaddle.position = CGPoint(x: touchLocation.x, y: myPaddle.position.y)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isFingerOnPaddle = false
    }
    

    
    
    
    
    
    
}
