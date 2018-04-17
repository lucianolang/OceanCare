/*:
 
 Created by Luciano Gucciardo on 21/03/2018.
 Copyright © 2018 Luciano Gucciardo. All rights reserved.
 
 #  OceanCare
 
 In this playground we will create a minigame, which reproduces the worst oil spills in history based on real data, while simulating ocean currents and spacial distribution of the Earths land. The player has to pan on the screen to collect the oil spilled.
 
 
 * Callout(Credits): Data courtesy of: [ChartsBin](http://chartsbin.com/view/mgz)
 
 **We will be using SpriteKit for this interactive view,** we will be managing **collissions** and **physical atributes** of the elements `SKNodes` in the our `SKScene`.
 */


/*:
 
 # Game Instructions
 
 1st. Press play to start the game
 
 2nd. Collect as much polution as possible
 
 3rd. Dont let the get too poluted or you'll loose
 
 4th. Read the code and have fun with SpriteKit like I did 😄
 
 */

import PlaygroundSupport
import SpriteKit


class MainScene: SKScene, SKPhysicsContactDelegate {
    
    // Here we declare all our Labels, Buttons and other variables and constants for our scene
    
    let dateLabel = SKLabelNode(fontNamed:"Futura")
    let caseLabel = SKLabelNode(fontNamed:"Futura")
    let locationLabel = SKLabelNode(fontNamed:"Futura")
    let scoreLabel = SKLabelNode(fontNamed:"Futura")
    let scoreLabelPlaceholder = SKLabelNode(fontNamed:"Futura")
    let playButton = SKSpriteNode(imageNamed: "PlayButton")
    let pauseButton = SKSpriteNode(imageNamed: "PauseButton")
    let resetButton = SKSpriteNode(imageNamed: "ResetButton")
    let player = SKSpriteNode(imageNamed: "Player")
    
    // This timer will let us run scheduled code
    var timer: Timer?
    
    // This variable will tell us where we are in time
    var currentDaySimulated = convertToDate(for: SpriteData.disasters[0].date)
    
    // The game simulation will last 2 minutes, you can make it last how much you want :)
    let gameDuration: TimeInterval = /*#-editable-code*/120/*#-end-editable-code*/
    
    // Number of disasters to simulate */
    var timerCounter: Int = SpriteData.disasters.count
    
    // Adjust the current force multiplier, feel free to play around with this, it is fun! 🙃
    let seaCurrentsForce = /*#-editable-code*/0.00005/*#-end-editable-code*/
    
    
    var tonnesRemoved = 0 {
        didSet{
            // Every time we remove a Tonne of oil we update this label
            scoreLabel.text = "\(tonnesRemoved/1000)"
        }
    }
    
    //: First code to run after the scene loads ⏲
    
    override func sceneDidLoad() {
        
        self.physicsWorld.contactDelegate = self
        // You can also play around with the gravity 🌝
        self.physicsWorld.gravity = CGVector(dx: /*#-editable-code*/0/*#-end-editable-code*/, dy: /*#-editable-code*/0/*#-end-editable-code*/)
        self.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width/1024*768)
        
        
    }
    
    override func didMove(to view: SKView) {
        
        // Create the oceans 🌊
        self.backgroundColor = UIColor(red: 158/255, green: 219/255, blue: 255/255, alpha: 1)
        
        // Display continents 🌎🌏
        let yOffset = (self.frame.height - (541*self.frame.width/1024))/2
        for (i, x, y)  in SpriteData.continentsPosition {
            
            let worldShape = SKSpriteNode(imageNamed: "WorldMap\(i)")
            worldShape.name = "WorldMap\(i)"
            worldShape.setScale(self.frame.width/1024)
            worldShape.position = CGPoint(x: (self.frame.width * x), y: ((self.frame.height - yOffset*2) * y) + yOffset)
            
            // Create their physics body 🌋 raise the land from the oceans
            worldShape.physicsBody = SKPhysicsBody(texture: worldShape.texture!, size: worldShape.size)
            worldShape.physicsBody?.isDynamic = false
            worldShape.physicsBody!.categoryBitMask = PhysicsMask.world
            worldShape.physicsBody!.collisionBitMask = PhysicsMask.barrel
            worldShape.zPosition = Z.sprites
            worldShape.physicsBody?.friction = 0
            addChild(worldShape)
            
        }
        
        // Create worst pollution sites (unfortunately) ⛽️
        for (i, x, y) in SpriteData.polutors {
            
            let newPolutor = Polutor(named: "Polutor\(i)")
            newPolutor.position = CGPoint(x: (self.frame.width * x), y: ((self.frame.height - yOffset*2) * y) + yOffset)
            newPolutor.setScale(self.frame.width/1024)
            newPolutor.alpha = 0.2
            
            addChild(newPolutor)
        }
        
        // Create player interface 🤠
        setUpPlayerInterface()
        
    }
    
    func setUpPlayerInterface() {
        
        // Here we set the spacing for our lauyot
        let spacing: CGFloat = self.size.width/30
        
        dateLabel.text = "Date Simulated"
        dateLabel.fontSize = 40
        dateLabel.fontColor = .black
        dateLabel.zPosition = Z.HUD
        dateLabel.horizontalAlignmentMode = .left
        dateLabel.position = CGPoint(x: spacing, y: size.height - dateLabel.frame.height/1.5 - spacing)
        addChild(dateLabel)
        
        scoreLabelPlaceholder.text = "Thousand\nTonnes Collected"
        scoreLabelPlaceholder.fontSize = 15
        scoreLabelPlaceholder.numberOfLines = 2
        scoreLabelPlaceholder.fontColor = .black
        scoreLabelPlaceholder.zPosition = Z.HUD
        scoreLabelPlaceholder.horizontalAlignmentMode = .right
        scoreLabelPlaceholder.position = CGPoint(x: self.size.width - spacing*1.5, y: spacing*0.8)
        addChild(scoreLabelPlaceholder)
        
        scoreLabel.text = "       0"
        scoreLabel.fontSize = 40
        scoreLabel.fontColor = .black
        scoreLabel.zPosition = Z.HUD
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: scoreLabelPlaceholder.frame.minX - spacing*0.2, y: spacing)
        addChild(scoreLabel)
        
        locationLabel.text = "Location"
        locationLabel.fontSize = 20
        locationLabel.fontColor = .black
        locationLabel.zPosition = Z.HUD
        locationLabel.horizontalAlignmentMode = .left
        locationLabel.position = CGPoint(x: spacing, y: spacing/2)
        addChild(locationLabel)
        
        caseLabel.text = "Case Name"
        caseLabel.fontSize = 25
        caseLabel.fontColor = .black
        caseLabel.zPosition = Z.HUD
        caseLabel.horizontalAlignmentMode = .left
        caseLabel.position = CGPoint(x: spacing, y: locationLabel.frame.height + spacing)
        addChild(caseLabel)
        
        playButton.name = "play"
        playButton.zPosition = Z.HUD
        playButton.size = SpriteSize.playButton
        playButton.position = CGPoint(x: self.size.width - spacing*1.5, y: self.size.height - spacing*1.5)
        addChild(playButton)
        
        pauseButton.name = "pause"
        pauseButton.zPosition = Z.HUD
        pauseButton.position = CGPoint(x: self.size.width - spacing*1.5, y: self.size.height - spacing*1.5)
        pauseButton.size = SpriteSize.playButton
        pauseButton.isHidden = true
        addChild(pauseButton)
        
        resetButton.name = "reset"
        resetButton.zPosition = Z.HUD
        resetButton.size = SpriteSize.resetButton
        resetButton.position = CGPoint(x: playButton.frame.minX - spacing*1.5, y: self.size.height - spacing*1.5)
        addChild(resetButton)
        
        player.name = "player"
        player.size = SpriteSize.playerAim
        player.isHidden = true
        player.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "Player.png"), size: SpriteSize.playerAim)
        player.physicsBody!.categoryBitMask = PhysicsMask.player
        player.physicsBody!.contactTestBitMask = PhysicsMask.barrel
        player.physicsBody!.collisionBitMask = PhysicsMask.barrel
        player.physicsBody?.isDynamic = false
        player.zPosition = Z.HUD
        addChild(player)
    }
    
    @objc func updateScene() {
        
        if self.children.count < 90 {
            if timerCounter != 0 {
                
                // What disaster we are going to recreate now?
                let caseNumber = SpriteData.disasters.count - timerCounter
                
                // Updating the labels...
                locationLabel.text = SpriteData.disasters[caseNumber].location
                caseLabel.text = SpriteData.disasters[caseNumber].caseName
                dateLabel.text = SpriteData.disasters[caseNumber].date
                
                // Selecting the polutor to explode
                let polutorToExplode = self.childNode(withName: "Polutor\(SpriteData.disasters[caseNumber].locationInMap)") as! Polutor
                
                // Recreate the spill here!
                polutorToExplode.recreateDisaster(tonnesOfOil: SpriteData.disasters[caseNumber].tonsSpilled)
                
                // Pass to the next disaster
                timerCounter -= 1
                
            } else {
                
                // Game has ended if timer is 0
                self.playButton.isHidden = false
                self.pauseButton.isHidden = true
                timerCounter = SpriteData.disasters.count
                self.timer?.invalidate()
                
            }
        } else {
            
            // if the scene has more than 90 children the scene is too poluted, the player must restart
            timer?.invalidate()
            self.isPaused = true
            let shade = SKSpriteNode(color: .white, size: CGSize(width: earthView.frame.size.width * 3, height: earthView.frame.size.height * 3))
            shade.name = "shade"
            shade.alpha = 0.3
            shade.zPosition = Z.mask
            addChild(shade)
            dateLabel.text = "Try Again 😕"
            caseLabel.text = "Drag your finger to collect pollution"
            locationLabel.text = "The ocean is too poluted to continue playing"
            playButton.isHidden = true
            pauseButton.isHidden = true
            resetButton.size = SpriteSize.playButton
            
        }
        
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Executed if the player makes contact with the polution.
        if contact.bodyA.categoryBitMask == PhysicsMask.player && contact.bodyB.categoryBitMask == PhysicsMask.barrel {
            // Find out which type of polution it is
            if contact.bodyB.node?.name == "barrelXL" {
                // Update the score counter
                tonnesRemoved += 100000
            } else if contact.bodyB.node?.name == "barrelL" {
                tonnesRemoved += 50000
            } else if contact.bodyB.node?.name == "barrel" {
                tonnesRemoved += 10000
            }
            // Remove it from the scene
            contact.bodyB.node?.removeFromParent()
        }
    }
    
    // Multiple Touches Began
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //With this test we make sure the touch we are using is the first
        guard let touch = touches.first else { return }
        // We show up the player
        player.isHidden = false
        // Then we place it in the position
        player.position = touch.location(in: self)
    }
    
    // Multiple Touches Moved
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        // Then we place it in the position
        player.position = touch.location(in: self)
        
    }
    
    // User lift the finger
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        // Player released the
        player.isHidden = true
        
        if let nodeName = self.atPoint(touch.location(in: self)).name {
            
            
            switch nodeName {
            // Button was touched to start Game
            case "play":
                
                // Resume Scene
                self.isPaused = false
                
                // We select display the pause button
                playButton.isHidden = true
                pauseButton.isHidden = false
                
                let timePerScene = TimeInterval((gameDuration/Double(timerCounter)))
                
                timer = Timer.scheduledTimer(timeInterval: timePerScene, target: self,   selector: (#selector(self.updateScene)), userInfo: nil, repeats: true)
                
            case "pause":
                
                // We pause the timer
                timer?.invalidate()
                // Freeze the scene
                self.isPaused = true
                // Toogle the play/pause
                playButton.isHidden = false
                pauseButton.isHidden = true
                
            case "reset":
                
                resetButton.size = SpriteSize.resetButton
                if let shade = self.childNode(withName: "shade") {
                    shade.removeFromParent()
                }
                self.isPaused = true
                if timer != nil {
                    timer?.invalidate()
                }
                currentDaySimulated = convertToDate(for: SpriteData.disasters[0].date)
                playButton.isHidden = false
                pauseButton.isHidden = true
                for element in self.children {
                    if element.physicsBody?.isDynamic == true {
                        element.removeFromParent()
                    }
                }
                dateLabel.text = "Tap Play to Start"
                scoreLabel.text = "        0"
                locationLabel.text = "Location"
                caseLabel.text = "Case Name"
                
            default:
                break
            }
        }
    }
    
    
    override func didSimulatePhysics() {
        
        for node in self.children {
            
            if node.physicsBody?.isDynamic == true {
                
                let x = node.position.x*self.size.width/1024
                let y = node.position.y*self.size.height/786
                
                // Here we evaluate the position of the polution and apply the current force ♒️
                
                if (156.5...299.5 ~= x) && (303.5...450.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.4778 * seaCurrentsForce, dy: -0.5222 * seaCurrentsForce))}
                if (264.5...465.5 ~= x) && (411.5...667.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: -0.393 * seaCurrentsForce, dy: -0.607 * seaCurrentsForce))}
                if (181.5...349.5 ~= x) && (114.5...273.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.5354 * seaCurrentsForce, dy: 0.4646 * seaCurrentsForce))}
                if (343.5...488.5 ~= x) && (223.5...429.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: -0.298 * seaCurrentsForce, dy: -0.702 * seaCurrentsForce))}
                if (747.5...900.5 ~= x) && (436.5...665.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: -0.2912 * seaCurrentsForce, dy: 0.7088 * seaCurrentsForce))}
                if (874.5...1058.5 ~= x) && (173.5...338.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.5638 * seaCurrentsForce, dy: -0.4362 * seaCurrentsForce))}
                if (788.5...973.5 ~= x) && (195.5...447.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.3586 * seaCurrentsForce, dy: 0.6414 * seaCurrentsForce))}
                if (795.5...1071.5 ~= x) && (327.5...455.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: -0.8627 * seaCurrentsForce, dy: 0.1373 * seaCurrentsForce))}
                if (624.5...909.5 ~= x) && (404.5...519.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: -0.925 * seaCurrentsForce, dy: -0.075 * seaCurrentsForce))}
                if (501.5...932.5 ~= x) && (537.5...706.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.8275 * seaCurrentsForce, dy: 0.1725 * seaCurrentsForce))}
                if (555.5...732.5 ~= x) && (295.5...637.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: -0.2414 * seaCurrentsForce, dy: -0.7586 * seaCurrentsForce))}
                if (210.5...383.5 ~= x) && (221.5...390.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.5141 * seaCurrentsForce, dy: 0.4859 * seaCurrentsForce))}
                if (236.5...408.5 ~= x) && (46.5...360.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.2517 * seaCurrentsForce, dy: -0.7483 * seaCurrentsForce))}
                if (-31.5...381.5 ~= x) && (54.5...179.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.926 * seaCurrentsForce, dy: -0.074 * seaCurrentsForce))}
                if (485.5...1066.5 ~= x) && (63.5...173.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.9796 * seaCurrentsForce, dy: -0.0204 * seaCurrentsForce))}
                if (348.5...575.5 ~= x) && (63.5...290.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.5 * seaCurrentsForce, dy: 0.5 * seaCurrentsForce))}
                if (219.5...442.5 ~= x) && (291.5...480.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: -0.5802 * seaCurrentsForce, dy: 0.4198 * seaCurrentsForce))}
                if (256.5...391.5 ~= x) && (571.5...713.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.4545 * seaCurrentsForce, dy: -0.5455 * seaCurrentsForce))}
                if (115.5...382.5 ~= x) && (582.5...725.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.7952 * seaCurrentsForce, dy: -0.2048 * seaCurrentsForce))}
                if (-40.5...140.5 ~= x) && (159.5...295.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: -0.6923 * seaCurrentsForce, dy: -0.3077 * seaCurrentsForce))}
                if (21.5...141.5 ~= x) && (148.5...328.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: -0.2 * seaCurrentsForce, dy: 0.8 * seaCurrentsForce))}
                if (-27.5...161.5 ~= x) && (173.5...433.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.3574 * seaCurrentsForce, dy: -0.6426 * seaCurrentsForce))}
                if (-46.5...150.5 ~= x) && (350.5...468.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: -0.8435 * seaCurrentsForce, dy: -0.1565 * seaCurrentsForce))}
                if (112.5...241.5 ~= x) && (385.5...508.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.5577 * seaCurrentsForce, dy: -0.4423 * seaCurrentsForce))}
                if (112.5...219.5 ~= x) && (343.5...473.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.1892 * seaCurrentsForce, dy: 0.8108 * seaCurrentsForce))}
                if (-23.5...195.5 ~= x) && (382.5...499.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.875 * seaCurrentsForce, dy: 0.125 * seaCurrentsForce))}
                if (-48.5...210.5 ~= x) && (413.5...526.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: -0.9244 * seaCurrentsForce, dy: 0.0756 * seaCurrentsForce))}
                if (128.5...274.5 ~= x) && (426.5...670.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: -0.2421 * seaCurrentsForce, dy: 0.7579 * seaCurrentsForce))}
                if (-35.5...280.5 ~= x) && (582.5...717.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.8606 * seaCurrentsForce, dy: 0.1394 * seaCurrentsForce))}
                if (447.5...605.5 ~= x) && (380.5...692.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: -0.2148 * seaCurrentsForce, dy: 0.7852 * seaCurrentsForce))}
                if (252.5...618.5 ~= x) && (560.5...726.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.8012 * seaCurrentsForce, dy: 0.1988 * seaCurrentsForce))}
                if (345.5...546.5 ~= x) && (396.5...521.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: -0.8016 * seaCurrentsForce, dy: -0.1984 * seaCurrentsForce))}
                if (304.5...488.5 ~= x) && (202.5...308.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.9333 * seaCurrentsForce, dy: 0.0667 * seaCurrentsForce))}
                if (374.5...620.5 ~= x) && (218.5...352.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: -0.8111 * seaCurrentsForce, dy: 0.1889 * seaCurrentsForce))}
                if (606.5...816.5 ~= x) && (345.5...455.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: -0.9167 * seaCurrentsForce, dy: -0.0833 * seaCurrentsForce))}
                if (731.5...1065.5 ~= x) && (564.5...701.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.8635 * seaCurrentsForce, dy: 0.1365 * seaCurrentsForce))}
                if (883.5...1069.5 ~= x) && (401.5...663.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: -0.3468 * seaCurrentsForce, dy: -0.6532 * seaCurrentsForce))}
                if (853.5...1075.5 ~= x) && (182.5...302.5 ~= y) {node.physicsBody?.applyImpulse(CGVector(dx: 0.8592 * seaCurrentsForce, dy: 0.1408 * seaCurrentsForce))}
                    
                    // Make the earth round, if an element goes out of the screen then it reappears on the other side.
                if x < 0 {
                    //send it to the other side
                    node.position.x = self.size.width - 5
                } else if x > self.size.width {
                    node.position.x = 5
                }
            }
        }
    }
}

public func convertToDate(for string: String) -> Date {
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM/dd/yyyy"
    
    return dateFormatter.date(from: string) ?? Date()
    
}



public class Polutor: SKSpriteNode {
    
    // Loading the looks of the polutors
    let textureIdle = SKTexture(imageNamed: "Polutor.png")
    
    public func recreateDisaster(tonnesOfOil: Int) {
        
        // Make site appear active
        self.alpha = 1
        
        // Now, based on the size of the spill we create different sizes on barrels
        
        // 1 ExtraLargeBarrels = 100000 tons of oil spilled
        let numberOfExtraLargeBarrels = Int(tonnesOfOil/100000)
        
        for i in 0...numberOfExtraLargeBarrels {
            delay(0.1 * Double(i)) {
                let barrel = Polution(named: "barrelXL")
                barrel.position = self.position
                self.parent?.addChild(barrel)
            }
        }
        
        // 1 LargeBarrel = 50000 tons of oil spilled
        let numberOfLargeBarrels = Int((tonnesOfOil % 100000)/50000)
        
        for i in 0...numberOfLargeBarrels {
            delay(0.1 * Double(i)) {
                let barrel = Polution(named: "barrelL")
                barrel.position = self.position
                self.parent?.addChild(barrel)
            }
        }
        
        // 1 Barrel = 20000 tons of oil spilled
        let numberOfSmallBarrels = (Int((tonnesOfOil % 50000)/20000)) == 0 ? Int((tonnesOfOil % 50000)/20000) : 1
        
        for i in 0...numberOfSmallBarrels {
            delay(0.1 * Double(i)) {
                let barrel = Polution(named: "barrel")
                barrel.position = self.position
                self.parent?.addChild(barrel)
            }
        }
        
        // We turn back the Polutor to "sleeping" state
        self.alpha = 0.2
    }
    
    public init(named: String) {
        super.init(texture: textureIdle, color: .clear, size: SpriteSize.polutor)
        self.name = named
        self.zPosition = Z.sprites
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

public class Polution: SKSpriteNode {
    
    public init(named: String) {
        
        super.init(texture: SKTexture(), color: .clear, size: SpriteSize.barrel)
        self.name = named
        self.texture = SKTexture(imageNamed: "Barrel.png")
        
        // Depending on the name of our barrel we will give it a different size
        switch named {
        case "barrel":
            self.size = SpriteSize.barrel
        case "barrelL":
            self.size = SpriteSize.barrelL
        case "barrelXL":
            self.size = SpriteSize.barrelXL
        default:
            self.size = SpriteSize.barrel
        }
        
        self.physicsBody = SKPhysicsBody(texture: self.texture!, size: self.size)
        self.physicsBody!.isDynamic = true
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.friction = 0
        
        //Who am i
        self.physicsBody!.categoryBitMask = PhysicsMask.barrel
        // Who do i want to test collisions with
        self.physicsBody!.contactTestBitMask = PhysicsMask.player
        // Who do I want to colide with
        self.physicsBody!.collisionBitMask = PhysicsMask.world
        self.zPosition = Z.sprites
        
        
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}



public enum SpriteSize {
    public static let polutor = CGSize(width: 18, height: 18)
    public static let barrel = CGSize(width: 4, height: 7)
    public static let barrelL = CGSize(width: 4.57, height: 8)
    public static let barrelXL = CGSize(width: 5.14, height: 9)
    public static let playButton = CGSize(width: 55, height: 55)
    public static let resetButton = CGSize(width: 30, height: 30)
    public static let playerAim = CGSize(width: 54, height: 54)
}

public enum PhysicsMask {
    public static let player: UInt32 = 0x1 << 1    // 2   00000010
    public static let barrel: UInt32 = 0x1 << 4   // 16  00010000
    public static let world: UInt32 = 0x1 << 5     // 32  00100000
}

public enum Z {
    public static let background: CGFloat = -1.0
    public static let sprites: CGFloat = 10.0
    public static let mask: CGFloat = 50.0
    public static let HUD: CGFloat = 100.0
}

/*:
 
 #  CONSTANTS
 
 Here we save all the reusable data we need in our project
 
 */

public enum SpriteData {
    
    // Here we assign the points relative to our prototype so we can match it to the code
    
    public static let continentsPosition: [(i: Int,xProportion: CGFloat,yProportion: CGFloat)] = [
        (1,0.18848,0.50086),
        (2,0.34229,0.82974),
        (3,0.46045,0.84456),
        (4,0.70654,0.57858),
        (5,0.61035,0.35924),
        (6,0.79883,0.44646),
        (7,0.89551,0.66839),
        (8,0.88232,0.43437),
        (9,0.87012,0.27375),
        (10,0.97266,0.22798),
        (11,0.5,-0.2),
        (12,0.5,1.2)
    ]
    
    public static let polutors: [(id: Int, x: CGFloat, y: CGFloat)] = [
        (0, x: 0.03125, y: 0.58549),
        (1, x: 0.11035, y: 0.65976),
        (2, x: 0.04883, y: 0.83656),
        (3, x: 0.25762, y: 0.48877),
        (4, x: 0.29883, y: 0.65285),
        (5, x: 0.20410, y: 0.39033),
        (6, x: 0.23316, y: 0.05599),
        (7, x: 0.38184, y: 0.35924),
        (8, x: 0.54590, y: 0.16171),
        (9, x: 0.58301, y: 0.29361),
        (10, x: 0.45605, y: 0.26770),
        (11, x: 0.47949, y: 0.44387),
        (12, x: 0.43359, y: 0.74093),
        (13, x: 0.43848, y: 0.85147),
        (14, x: 0.68848, y: 0.51468),
        (15, x: 0.48828, y: 0.69603),
        (16, x: 0.76074, y: 0.52332),
        (17, x: 0.81543, y: 0.20380),
        (18, x: 0.94922, y: 0.65976),
        (19, x: 0.63477, y: 0.55613),
        (20, x: 0.86328, y: 0.37824),
        (21, x: 0.84570, y: 0.64421),
        (22, x: 0.41309, y: 0.58031),
        (23, x: 0.20703, y: 0.55613),
        (24, x: 0.55371, y: 0.67358),
        (25, x: 0.49391, y: 0.92746)
    ]
    
    /*:
     
     * Callout(Credits):  Data courtesy of: http://chartsbin.com
     
     */
    
    
    
    public static let disasters: [(date: String, location: String, caseName: String, locationInMap: Int, tonsSpilled: Int)] = [
        ("6/12/1966", "Brazil", "Sinclair Petrolore", 7, 59860),
        ("3/18/1967", "Isles of Scilly, England", "Torrey Canyon", 13, 119000),
        ("2/29/1968", "Pacific Ocean, near Warrenton, Oregon, USA", "Mandoil II", 1, 42860),
        ("6/13/1968", "65 miles ENE of Durban, South Africa", "World Glory", 8, 48300),
        ("1/28/1969", "Santa Barbara, California", "Well blowout", 1, 14000),
        ("1/6/1970", "Indian Ocean, Seychelles", "Ennerdale", 9, 46940),
        ("1/12/1970", "Bermuda", "Chryssi", 23, 32000),
        ("3/20/1970", "Sweden, Trälhavet Bay", "Othello", 25, 60000),
        ("2/27/1971", "Cape Agulhas, South Africa", "Wafra", 8, 63000),
        ("7/12/1971", "North Sea, Belgium", "Texaco Denmark", 12, 107140),
        ("12/19/1972", "Gulf of Oman", "Sea Star", 19, 115000),
        ("10/6/1973", "Southeast Pacific Ocean off west coast of Chile", "Napier", 6, 38440),
        ("9/8/1974", "First Narrows, Strait of Magellan, Chile", "VLCC Metula", 6, 51000),
        ("9/11/1974", "Tokyo Bay, Honshu Island, Japan", "Yuyo Maru No. 10", 18, 52836),
        ("1/13/1975", "333 km west of Iwo Jima Island, Japan", "British Ambassador", 18, 46000),
        ("1/29/1975", "Leixoes, Portugal", "Jakob Maersk", 14, 88000),
        ("1/31/1975", "Delaware River, Marcus Hook, Pennsylvania", "Corinthos", 4, 35700),
        ("5/13/1975", "Caribbean Sea, 111 km NW of Puerto Rico, USA", "Epic Colocotronis", 23, 58000),
        ("6/2/1976", "Pacific Ocean, 56 km W of Punta Manglares, Colombia", "Saint Peter", 5, 35030),
        ("12/5/1976", "La Coruña, Spain", "Urquiola", 15, 100000),
        ("12/15/1976", "29 miles southeast of Nantucket Island, Massachusetts", "Argo Merchant", 4, 28000),
        ("2/23/1977", "300 nautical miles off Honolulu", "Hawaiian Patriot", 0, 95000),
        ("4/22/1977", "Norway, North Sea", "Ekofisk Bravo oil field", 13, 27600),
        ("3/16/1978", "Brittany, France", "Amoco Cadiz", 12, 223000),
        ("5/25/1978", "Ahvazin, Iran", "Pipeline No. 126 well and pipeline", 19, 95240),
        ("7/12/1978", "Strait of Malacca, near Dumai, Indonesia", "Tadotsu", 16, 44900),
        ("12/31/1978", "off the coast of La Coruna, Galicia", "Andros Patria", 15, 60000),
        ("3/6/1979", "Mexico, Gulf of Mexico", "IXTOC I", 23, 470000),
        ("6/6/1979", "Forcados, Nigeria", "Storage tank Tank #6", 11, 81290),
        ("7/19/1979", "Off Tobago West Indies", "Atlantic Empress", 3, 287000),
        ("8/1/1979", "Bantry Bay, Ireland", "Betelgeuse", 13, 40000),
        ("11/15/1979", "Newtown Creek, Greenpoint, Brooklyn, New York", "Oil Spill", 4, 55250),
        ("11/15/1979", "Istanbul, Turkey", "Independenta", 24, 95000),
        ("1/8/1980", "800 km southeast of Tripoli, Libya", "Well D-103", 19, 142860),
        ("2/23/1980", "Navarino Bay Greece", "Irenes Serenade", 24, 100000),
        ("7/3/1980", "Brittany, France", "Tanio", 12, 13500),
        ("12/29/1980", "Arzew Harbor, Algeria", "Juan Antonio Lavalleja", 15, 37400),
        ("8/20/1981", "Shuaiba, Kuwait", "Shuaiba Petroleum Tank", 19, 106120),
        ("7/1/1983", "Gulf of Oman, Ras al Hadd, 93 km from Muscat, Oman", "Assimi", 19, 53740),
        ("8/6/1983", "Off Saldanha Bay South Africa", "Castillo de bellver", 8, 252000),
        ("9/12/1983", "Persian Gulf, 30 km east-northeast of Doha, Qatar", "Pericles GC", 19, 47620),
        ("10/2/1983", "Persian Gulf, Iran", "Nowruz Oil Field", 19, 260000),
        ("6/12/1985", "Off Kharg Island Gulf of Iran", "NOVA", 19, 70000),
        ("4/1/1988", "Floreffe, Pennsylvania", "Ashland Petroleum Company", 4, 10000),
        ("10/11/1988", "700 nautical miles off Nova Scotia Canada", "ODYSSEY", 4, 132000),
        ("1/23/1989", "Prince of Wales Island, Alaska", "EXXON VALDEZ", 2, 37000),
        ("12/19/1989", "400 miles north of Las Palmas, Canary Islands", "Khark 5", 22, 80000),
        ("8/6/1990", "Gulf of Mexico, 57 miles SE of Galveston, Texas", "M/V Megaborg", 23, 16501),
        ("1/19/1991", "Persian Gulf, Kuwait", "Gulf War oil spill", 19, 1091405),
        ("5/28/1991", "700 nautical miles off Angola", "ABT Summer", 10, 260000),
        ("7/21/1991", "Cervantes, Western Australia", "Kirki", 17, 17280),
        ("11/4/1991", "Mediterranean Sea near Genoa, Italy", "Amoco Haven tanker disaster", 15, 144000),
        ("2/3/1992", "Uzbekistan", "Fergana Valley", 24, 285000),
        ("3/12/1992", "La Coruna Spain", "Aegean Sea", 15, 74000),
        ("4/19/1992", "25 miles north of Maputo, Mozambique, 6 miles offshore", "Katina P", 9, 66700),
        ("5/1/1993", "Shetland Islands UK", "M/V Braer", 13, 85000),
        ("3/31/1994", "E coast of the United Arab Emirates near Fujaira in the Gulf of Oman", "Seki Oil Spill", 19, 15900),
        ("10/25/1994", "Usinsk in Northern Russia (Komi Republic)", "Kharyaga-Usinsk Pipeline Spill", 25, 104420),
        ("2/15/1996", "Milford Haven UK", "Sea Empress", 13, 72000),
        ("12/12/1999", "France, Bay of Biscay", "Erika", 15, 20000),
        ("10/6/2002", "Yemen, Gulf of Aden", "Limburg", 19, 12200),
        ("11/15/2002", "Off Spanish coast", "M/V Prestige", 15, 64000),
        ("7/27/2003", "off Karachi ( Pakistan )", "Tasman Spirit", 14, 30000),
        ("6/9/2005", "Cox Bay, Louisiana , United States", "Bass Enterprises (Hurricane Katrina)", 23, 12000),
        ("7/15/2006", "Lebanon conflict", "Jiyeh power station oil spill", 19, 30000),
        ("7/12/2007", "South Korea, Yellow Sea", "MT Hebei Spirit", 21, 10800),
        ("8/21/2009", "Australia, Timor Sea", "Montara oil spill", 20, 30000),
        ("4/21/2010", "Gulf of Mexico", "Deepwater Horizon", 23, 633116)
        ]
    
}

let earthView = SKView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width/1024*768))

let earthScene: MainScene = MainScene()

earthScene.scaleMode = .aspectFit

earthView.presentScene(earthScene)
earthView.backgroundColor = .clear

PlaygroundPage.current.liveView = earthView


