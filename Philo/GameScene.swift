//
//  GameScene.swift
//  Philo
//
//  Created by Georges Kanaan on 17/02/2017.
//
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
  
  var entities = [GKEntity]()
  var graphs = [String : GKGraph]()
  
  private var lastUpdateTime : TimeInterval = 0// Used to track the time between frames
  private var label : SKLabelNode!// Main label that shows how to play and game over.
  
  private var touchValid : Bool = true// Used to track wether a color is on screen (hence the touch is valid and won't cause a game over)
  private var randomSource : GKLinearCongruentialRandomSource!// Random numbe rgenerator
  private var gamePlaying : Bool = false// Used to track the state of the game

  private var secondsTillPressValid : Float = 0// Stores the seconds till touchValid should bne true, and since it was if < 0
  private var timeForPress : Float = 0// Holds the randomly generated value time for the press time
  private let maxPressDisplayTime : Float = 5.0// Max display time for press color, in seconds.
  private let maxTimeForColors : Float = 14.0// Max time the colors should be shown, in seconds.
  private let maxTimePerColor : Float = 3.0// Max time an individual color should be shown, in seconds.
  private var colorToPress : UIColor!// The color that should be pressed. Will be generateRandomColor().

  private var score : Int = 0;
  
  override func sceneDidLoad() {
    // Initialize the random number source
    self.randomSource = GKLinearCongruentialRandomSource.init()

    // Generate a random color to press this time
    self.colorToPress = UIColor.black;
    self.backgroundColor = self.colorToPress;
    
    self.lastUpdateTime = 0// Initialize
        
    // Get label node from scene and store it for use later
    self.label = self.childNode(withName: "helloLabel") as? SKLabelNode
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    // If game is in progress, handle the touch
    if self.gamePlaying {
      self.handleGameTouch();
      return;
    }
    
    // Remove the label by scaling it out, on first touch.
    if (!self.gamePlaying) {
      self.gamePlaying = true
      self.score = 0
      
      self.label.run(SKAction.init(named: "FadeOut")!, withKey: "fadeOut")
      self.label.text = "Hits: \(self.score)"
      
      // Start the game
      self.touchValid = false
      self.secondsTillPressValid = self.randomSource.nextUniform()*maxTimeForColors;
      
      // Randomize the background color
      self.randomizeBackgroundColorUntilPressColor()
    }
  }
  
  func handleGameTouch() {// Will only be called by a touch if gamePlaying is true
    if self.touchValid && self.gamePlaying {// Check if the user was right to press
      // Reset
      self.touchValid = false
      self.secondsTillPressValid = self.randomSource.nextUniform()*maxTimeForColors;
      self.timeForPress = 0;
      
      // Randomize the background color
      self.randomizeBackgroundColorUntilPressColor()
      
      // Update score
      self.score += 1
      self.label.text = "Hits: \(self.score)"
      
    } else if !self.touchValid && self.gamePlaying {// Game over
      // Return game over label to front
      self.label.text = "You Lost: \(score)"
      self.label.run(SKAction.init(named: "FadeIn")!, withKey: "fadeIn")
      
      // Reset the game
      self.touchValid = true
      self.secondsTillPressValid = 0
      self.gamePlaying = false
      self.score = 0
    }
  }
  
  override func update(_ currentTime: TimeInterval) {// Called before each frame is rendered
    // Initialize lastUpdateTime if it has not already been
    if (self.lastUpdateTime == 0 || self.isPaused) {
      self.lastUpdateTime = currentTime
    }
    
    // Calculate time since last update
    let dt = currentTime - self.lastUpdateTime
    
    // Update entities
    for entity in self.entities {
      entity.update(deltaTime: dt)
    }
    
    self.lastUpdateTime = currentTime
    
    // If the game is waiting to allow a valid press, decrement the number of frames till press valid.
    if self.gamePlaying {
      self.secondsTillPressValid -= Float(dt);// Substract the time in seconds since the last frame.
      
      
      // Check if we should allow a valid press and color black
      if (self.secondsTillPressValid <= 0 && !self.touchValid) {
        // First allow touches and reset the framesTillValid
        self.touchValid = true
        self.secondsTillPressValid = 0
        
        // Color to press background
        self.backgroundColor = self.colorToPress;
        
        // Time the black should be displayed. Between 0 and 5 seconds.
        self.timeForPress = self.randomSource.nextUniform()*maxPressDisplayTime
        if self.timeForPress < 0.6 {
          self.timeForPress = 0.6;
        }
        
        return;
      }
      
      // Check if the background is black (touch valid) and the time has run out
      if (self.secondsTillPressValid <= -self.timeForPress && self.touchValid) {
        
        // Reset
        self.touchValid = false
        
        // Handle as if a touch to go to game over if necessary.
        self.handleGameTouch()
        
        return;
      }
    }
  }
  
  func randomizeBackgroundColorUntilPressColor() {
    if self.gamePlaying && !self.touchValid {
      let timeForColor = self.randomSource.nextUniform()*maxTimePerColor// Generate a first random time
      
      self.backgroundColor = generateRandomColor();
      
      let dispatchTime = DispatchTime.now() + Double(timeForColor)
      DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
        self.randomizeBackgroundColorUntilPressColor()
      }
    }
  }
  
  func generateRandomColor() -> UIColor {
    // Color the background
    let red = CGFloat(self.randomSource.nextUniform())
    let green = CGFloat(self.randomSource.nextUniform())
    let blue = CGFloat(self.randomSource.nextUniform())
    
    let generatedColor = UIColor.init(red: red, green: green, blue: blue, alpha: 1.0)
    return  (!generatedColor.isEqual(self.colorToPress)) ? generatedColor : generateRandomColor()
  }
}
