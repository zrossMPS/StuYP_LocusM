//
//  GameScene.swift
//  Solo Mission
//
//  Created by 박유빈 on 12/1/18.
//  Copyright © 2018 Yubin Park. All rights reserved.
//

import SpriteKit
import CoreMotion
import GameplayKit

  var gameScore = 0
class GameScene: SKScene , SKPhysicsContactDelegate {

    let scoreLabel = SKLabelNode(fontNamed: "font")
    
    var livesNumber = 3
    let livesLabel = SKLabelNode(fontNamed: "font")
    
    let player = SKSpriteNode(imageNamed: "rocket")
    
    let bulletSound = SKAction.playSoundFileNamed("steyraug-fire.wav", waitForCompletion: false)
    
    
    enum gameState{
        
        case preGame
        case inGame
        case afterGame
        
    }
    
    var currentGameState = gameState.inGame
    
    
    
    
    
    struct PhysicsCategories{
        
        static let None :  UInt32 = 0
        static let Player : UInt32 = 0b1 //1
        static let Bullet : UInt32 = 0b10 //2
        static let Enemy : UInt32 = 0b100 //4
    }
    
    func random() -> CGFloat{
        return CGFloat(Float(arc4random())/0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    
    
    
    var gameArea: CGRect
    
    override init(size: CGSize) {
        
        let maxAspectRatio: CGFloat = 16.0/9.0
        let playableWidth = size.height / maxAspectRatio
        let margin = (size.width - playableWidth)/2
        gameArea = CGRect(x: margin, y:0, width: playableWidth, height: size.height)
        
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func didMove(to view: SKView) {
        
        gameScore = 0
        self.physicsWorld.contactDelegate = self
        
        let background = SKSpriteNode(imageNamed: "background" )
        background.size=self.size
        background.position=CGPoint(x: self.size.width/2 , y:self.size.height/2)
        background.zPosition=0
        self.addChild(background)
        

        player.setScale(1)
        player.position = CGPoint(x: self.size.width/2,y: self.size.height*0.2)
        player.zPosition = 2
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody!.affectedByGravity = false
        player.physicsBody!.categoryBitMask = PhysicsCategories.Player
        player.physicsBody!.collisionBitMask = PhysicsCategories.None
        player.physicsBody!.contactTestBitMask = PhysicsCategories.Enemy
        
        self.addChild(player)
        
        scoreLabel.text = "score = 0 "
        scoreLabel.fontSize = 70
        scoreLabel.fontColor = SKColor.white
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabel.position = CGPoint(x: self.size.width*0.15 , y: self.size.height*0.9)
        scoreLabel.zPosition = 100
        self.addChild(scoreLabel)
        
        
        livesLabel.text = "Lives: 3"
        livesLabel.fontSize = 70
        livesLabel.fontColor = SKColor.white
        livesLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.right
        livesLabel.position = CGPoint(x: self.size.width*0.85, y:self.size.height*0.9)
        livesLabel.zPosition = 100
        self.addChild(livesLabel)
        
        startNewLevel()
        

    }
    
    func loseALife () {
        
        livesNumber -= 1
        livesLabel.text = "Lives \(livesNumber)"
        
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1, duration: 0.2)
        let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
        livesLabel.run(scaleSequence)
        
        if livesNumber == 0 {
            rungameOver()
        }
    }
    
   
    func addScore() {
        
        gameScore += 1
        scoreLabel.text = "Score: \(gameScore)"
        
    }
    
    func rungameOver() {
        
        currentGameState = gameState.afterGame
        self.removeAllActions()
        
        self.enumerateChildNodes(withName: "Bullet"){
            //making all the bullets to be gone and stopping the bullet
            bullet, stop in
            bullet.removeAllActions()
            
        }
        
        self.enumerateChildNodes(withName: "Enemy") {
            
            enemy, stop in
            
            enemy.removeAllActions()
            
        }
        
        let changeSceneAction = SKAction.run(changeScene)
        let waitToChanges = SKAction.wait(forDuration: 1)
        let changeSceneSequence = SKAction.sequence([waitToChanges, changeSceneAction])
        self.run(changeSceneSequence)
        
        
        
    }
    
    func changeScene(){
        
        let sceneToMoveTo = GameOverScene(size: self.size)
        sceneToMoveTo.scaleMode = self.scaleMode
        let myTransition = SKTransition.fade(withDuration: 0.5)
        self.view!.presentScene(sceneToMoveTo, transition: myTransition)
        
        
        
        
    }
    func didBegin(_ contact: SKPhysicsContact) {
        
        var body1 = SKPhysicsBody()
        var body2 = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            
            body1 = contact.bodyA
            body2 = contact.bodyB
        }
        else{
            body1 = contact.bodyB
            body2 = contact.bodyA
        }
        
        if body1.categoryBitMask == PhysicsCategories.Player && body2.categoryBitMask == PhysicsCategories.Enemy{
            //if the player has hit the enemy
            
            if body1.node != nil {
            spawnExplosion(spawnPosition: body1.node!.position)
            }
            if body2.node != nil{
            spawnExplosion(spawnPosition: body2.node!.position)
            }
            body1.node?.removeFromParent()
            body2.node?.removeFromParent()
            
            rungameOver()
            
        }
        
        if body2.node != nil{
            
            addScore()
            
            if body2.node!.position.y > self.size.height{
                return
            }
            else{
                spawnExplosion(spawnPosition: body2.node!.position)
            }
        }
        
        
        body1.node?.removeFromParent()
        body2.node?.removeFromParent()
        
    }
    
    func spawnExplosion(spawnPosition: CGPoint){
        let explosion = SKSpriteNode(imageNamed: "explosion")
        explosion.position = spawnPosition
        explosion.zPosition = 3
        explosion.setScale(0)
        self.addChild(explosion)
        
        let scaleIn = SKAction.scale(to: 1,duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        _ = SKAction.removeFromParent()
        
        _ = SKAction.sequence([scaleIn, fadeOut])
        
    }
    
    func startNewLevel(){
        
        
        let spawn = SKAction.run(spawnEnemy)
        let waitToSpawn = SKAction.wait(forDuration: 1)
        let spawnSequence = SKAction.sequence([waitToSpawn, spawn])
        let spawnForever = SKAction.repeatForever(spawnSequence)
        self.run(spawnForever, withKey: "spawnEnemies")
        
    }
    
    func fireBullet() {
        let bullet = SKSpriteNode(imageNamed: "bullet")
        bullet.name = "Bullet"
        bullet.setScale(1)
        bullet.position = player.position
        bullet.zPosition = 1
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody!.affectedByGravity = false
        bullet.physicsBody!.categoryBitMask=PhysicsCategories.Bullet
        bullet.physicsBody!.collisionBitMask = PhysicsCategories.None
        bullet.physicsBody!.contactTestBitMask = PhysicsCategories.Enemy
        
        self.addChild(bullet)
        
        let moveBullet = SKAction.moveTo(y: self.size.height + bullet.size.height, duration: 1)
        let deleteBullet = SKAction.removeFromParent()
        
        let bulletSequence = SKAction.sequence([bulletSound, moveBullet,deleteBullet])
        bullet.run(bulletSequence)
        
    }
    
    func spawnEnemy(){
        
        let randomXStart = random(min: gameArea.minX, max:gameArea.maxX)
        let randomXEnd = random(min:gameArea.minX, max:gameArea.maxX)
        
        let startPoint = CGPoint(x: randomXStart, y: self.size.height * 1.2 )
        let endPoint = CGPoint(x: randomXEnd, y: -self.size.height * 0.2)
        
        let enemy = SKSpriteNode(imageNamed: "Me")
        enemy.name = "Enemy"
        enemy.setScale(1)
        enemy.position = startPoint
        enemy.zPosition = 2
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody!.affectedByGravity = false
        enemy.physicsBody!.categoryBitMask = PhysicsCategories.Enemy
        enemy.physicsBody!.collisionBitMask = PhysicsCategories.None
        enemy.physicsBody!.contactTestBitMask = PhysicsCategories.Player | PhysicsCategories.Bullet
        
        self.addChild(enemy)
        
        let moveEnemy = SKAction.move(to: endPoint, duration: 1.5)
        
        let deleteEnemy = SKAction.removeFromParent()
        let loseALife = SKAction.run(self.loseALife)
        let enemySequence = SKAction.sequence([moveEnemy, deleteEnemy, loseALife])
        
        
        
        if currentGameState == gameState.inGame{
        enemy.run(enemySequence)
        }
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let amountToRotate = atan2(dy,dx)
        enemy.zRotation = amountToRotate
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if currentGameState == gameState.inGame{
        fireBullet()
        }
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch: AnyObject in touches{
            
            let pointOfTouch = touch.location(in: self)
            let previousPointOfTouch = touch.previousLocation(in: self)
            
            let amountDragged = pointOfTouch.x - previousPointOfTouch.x
            
            if currentGameState == gameState.inGame{
            player.position.x += amountDragged
            }
            
        
            if player.position.x > gameArea.maxX - player.size.width/2 {
                player.position.x = gameArea.maxX - player.size.width/2
            }
            
            if player.position.x < gameArea.minX + player.size.width/2 {
                player.position.x = gameArea.minX + player.size.width/2
            }
            
            
        }
        
        
    }
    
}

