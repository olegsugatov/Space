//
//  GameOverScene.swift
//  Space
//
//  Created by MedappMac on 23.07.14.
//  Copyright (c) 2014 oleg.kipling. All rights reserved.
//

import UIKit
import SpriteKit

class GameOverScene: SKScene {

    init(size:CGSize, won:Bool){
        super.init(size:size)
       
        self.backgroundColor = SKColor.black
        
        var message:NSString = NSString()
        
        if(won) {
            message = "You Win!"
        } else {
            message = "Game Over"
        }
        
        var label:SKLabelNode = SKLabelNode(fontNamed: "DamascusBold")
        label.text = message
        label.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        self.addChild(label)
        
        self.run(SKAction.sequence([SKAction.wait(forDuration: 3.0), SKAction.run({
            
            var transition:SKTransition = SKTransition.flipHorizontal(withDuration: 0.5)
            var scene:SKScene = GameScene(size: self.size)
            self.view.presentScene(scene,transition:transition)
            
                })
            ]))
    }
}
