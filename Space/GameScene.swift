//
//  GameScene.swift
//  Space
//
//  Created by oleg.kipling on 23.07.14.
//  Copyright (c) 2014 oleg.kipling. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var player:SKSpriteNode = SKSpriteNode()
    var lastYieldTimeInterval:TimeInterval = TimeInterval()
    var lastUpdateTimerInterval:TimeInterval = TimeInterval()
    var aliensDestroyed:Int = 0
    
    let alienCategory:UInt32 = 0x1 << 1
    let photonTorpedoCategory:UInt32 = 0x1 << 0
    
    /*override func didMoveToView(view: SKView) {
        /* Setup your scene here*/
        let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Hello, World!";
        myLabel.fontSize = 65;
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        
        self.addChild(myLabel)
    }*/
    
    init(size:CGSize){
        super.init(size: size)
        self.backgroundColor = SKColor.black
        player = SKSpriteNode(imageNamed: "shuttle")
        
        player.position = CGPoint(x: self.frame.size.width/2, y: player.size.height/2 + 20)
        self.addChild(player)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
    }
    
    func addAlien() {
       
        var alien:SKSpriteNode = SKSpriteNode(imageNamed: "alien")
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody.dynamic = true
        alien.physicsBody.categoryBitMask = alienCategory
        alien.physicsBody.contactTestBitMask = photonTorpedoCategory
        alien.physicsBody.collisionBitMask = 0
        
        let minX = alien.size.width/2
        let maxX = self.frame.size.width - alien.size.width/2
        let rangeX = maxX - minX
        let position:CGFloat = CGFloat(arc4random()).truncatingRemainder(dividingBy: CGFloat(rangeX)) + CGFloat(minX)
        
        alien.position = CGPoint(x: position, y: self.frame.size.height+alien.size.height)
        self.addChild(alien)
        
        let minDuration = 2
        let maxDuration = 4
        let rangeDuration = maxDuration - minDuration
        let duration = Int(arc4random()) % Int(rangeDuration) + Int(rangeDuration)
        
        var actionArray:NSMutableArray = NSMutableArray()
        
        actionArray.add(SKAction.move(to: CGPoint(x: position, y: -alien.size.height), duration:TimeInterval(duration)))
        actionArray.add(SKAction.run({
            var transition:SKTransition = SKTransition.flipHorizontal(withDuration: 0.5)
            var gameOverScene:SKScene = GameOverScene(size: self.size, won:false)
            self.view.presentScene(gameOverScene, transition:transition)
            }))
        
        actionArray.add(SKAction.removeFromParent())
        alien.runAction(SKAction.sequence(actionArray))
    }
    
    func updateWithTimeSinceLastUpdate(_ timeSinceLastUpdate:CFTimeInterval){
        
        lastYieldTimeInterval += timeSinceLastUpdate
        if(lastYieldTimeInterval > 1) {
           lastYieldTimeInterval = 0
           addAlien()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        var timeSinceLastUpdate = currentTime - lastUpdateTimerInterval
        lastUpdateTimerInterval = currentTime
        
        if(timeSinceLastUpdate > 1) {
           timeSinceLastUpdate = 1/60
           lastUpdateTimerInterval = currentTime
        }
        
        updateWithTimeSinceLastUpdate(timeSinceLastUpdate)
    }
    
    override func touchesEnded(_ touches: NSSet!, withEvent event: UIEvent!) {
        self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        
        var touch:UITouch = touches.anyObject() as UITouch
        var location:CGPoint = touch.location(in: self)
        
        var torpedo:SKSpriteNode = SKSpriteNode(imageNamed: "torpedo")
        torpedo.position = player.position
        
        torpedo.physicsBody = SKPhysicsBody(circleOfRadius: torpedo.size.width/2)
        torpedo.physicsBody.dynamic = true
        torpedo.physicsBody.categoryBitMask = photonTorpedoCategory
        torpedo.physicsBody.contactTestBitMask = alienCategory
        torpedo.physicsBody.collisionBitMask = 0
        torpedo.physicsBody.usesPreciseCollisionDetection = true
        
        var offset:CGPoint = vecSub(location, b: torpedo.position)

        if (offset.y < 0) {
            return
        }
        
        self.addChild(torpedo)
        var direction:CGPoint = vecNormalize(offset)
        
        var shotLenght:CGPoint = vecMult(direction, b: 1000)
        
        var finalDestination:CGPoint = vecAdd(shotLenght, b:torpedo.position)
        
        let velocity = 568/1
        let moveDuration:Float = Float(self.size.width) / Float(velocity)
        
        var actionArray:NSMutableArray = NSMutableArray()
        actionArray.add(SKAction.move(to: finalDestination, duration: TimeInterval(moveDuration)))
        actionArray.add(SKAction.removeFromParent())
        
        torpedo.runAction(SKAction.sequence(actionArray))
    }

    
    func didBegin(_ contact: SKPhysicsContact!) {
        
        var firstBody:SKPhysicsBody
        var secondBody:SKPhysicsBody
        
        if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if ((firstBody.categoryBitMask & photonTorpedoCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0) {
                torpedoDidCollideWithAlien(firstBody.node as SKSpriteNode, alien: secondBody.node as SKSpriteNode)
        }
    }
    
    
    func torpedoDidCollideWithAlien(_ torpedo:SKSpriteNode, alien:SKSpriteNode){
        println("HIT");
        torpedo.removeFromParent()
        alien.removeFromParent()
        
        aliensDestroyed++
        
        if (aliensDestroyed > 10){
            // Transition GameOver or Success
            var transition:SKTransition = SKTransition.flipHorizontal(withDuration: 0.5)
            var gameOverScene:SKScene = GameOverScene(size: self.size, won:true)
            self.view.presentScene(gameOverScene, transition:transition)
        }
    }
    
    
    func vecAdd(_ a:CGPoint, b:CGPoint) -> CGPoint {
        return CGPoint(x: a.x + b.x, y: a.y + b.y)
    }
    
    func vecSub(_ a:CGPoint, b:CGPoint) -> CGPoint {
        return CGPoint(x: a.x - b.x, y: a.y - b.y)
    }
    
    func vecMult(_ a:CGPoint, b:CGFloat) -> CGPoint {
        return CGPoint(x: a.x * b, y: a.y * b)
    }
    
    func vecLenght(_ a:CGPoint) -> CGFloat {
        return CGFloat(sqrtf(CFloat(a.x) * CFloat(a.x)+CFloat(a.y) * CFloat(a.y)))
    }
    
    func vecNormalize(_ a:CGPoint) -> CGPoint {
        var lenght:CGFloat = vecLenght(a)
        return CGPoint(x: a.x / lenght, y: a.y / lenght)
    }
}
