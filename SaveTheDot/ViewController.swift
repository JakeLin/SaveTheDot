//
//  ViewController.swift
//  SaveTheDot
//
//  Created by Jake Lin on 6/18/16.
//  Copyright © 2016 Jake Lin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  // MARK: - enum
  fileprivate enum ScreenEdge: Int {
    case top = 0
    case right = 1
    case bottom = 2
    case left = 3
  }
  
  fileprivate enum GameState {
    case ready
    case playing
    case gameOver
  }
  
  // MARK: - Constants
  fileprivate let radius: CGFloat = 10
  fileprivate let playerAnimationDuration = 5.0
  fileprivate let enemySpeed: CGFloat = 60 // points per second
  fileprivate let colors = [#colorLiteral(red: 0.08235294118, green: 0.6980392157, blue: 0.5411764706, alpha: 1), #colorLiteral(red: 0.07058823529, green: 0.5725490196, blue: 0.4470588235, alpha: 1), #colorLiteral(red: 0.9333333333, green: 0.7333333333, blue: 0, alpha: 1), #colorLiteral(red: 0.9411764706, green: 0.5450980392, blue: 0, alpha: 1), #colorLiteral(red: 0.1411764706, green: 0.7803921569, blue: 0.3529411765, alpha: 1), #colorLiteral(red: 0.1176470588, green: 0.6431372549, blue: 0.2941176471, alpha: 1), #colorLiteral(red: 0.8784313725, green: 0.4156862745, blue: 0.03921568627, alpha: 1), #colorLiteral(red: 0.7882352941, green: 0.2470588235, blue: 0, alpha: 1), #colorLiteral(red: 0.1490196078, green: 0.5098039216, blue: 0.8352941176, alpha: 1), #colorLiteral(red: 0.1137254902, green: 0.4156862745, blue: 0.6784313725, alpha: 1), #colorLiteral(red: 0.8823529412, green: 0.2, blue: 0.1607843137, alpha: 1), #colorLiteral(red: 0.7019607843, green: 0.1411764706, blue: 0.1098039216, alpha: 1), #colorLiteral(red: 0.537254902, green: 0.2352941176, blue: 0.662745098, alpha: 1), #colorLiteral(red: 0.4823529412, green: 0.1490196078, blue: 0.6235294118, alpha: 1), #colorLiteral(red: 0.6862745098, green: 0.7137254902, blue: 0.7333333333, alpha: 1), #colorLiteral(red: 0.1529411765, green: 0.2196078431, blue: 0.2980392157, alpha: 1), #colorLiteral(red: 0.1294117647, green: 0.1843137255, blue: 0.2470588235, alpha: 1), #colorLiteral(red: 0.5137254902, green: 0.5843137255, blue: 0.5843137255, alpha: 1), #colorLiteral(red: 0.4235294118, green: 0.4745098039, blue: 0.4784313725, alpha: 1)]
  
  // MARK: - fileprivate
  fileprivate var playerView = UIView(frame: .zero)
  fileprivate var playerAnimator: UIViewPropertyAnimator?
  
  fileprivate var enemyViews = [UIView]()
  fileprivate var enemyAnimators = [UIViewPropertyAnimator]()
  fileprivate var enemyTimer: Timer?
  
  fileprivate var displayLink: CADisplayLink?
  fileprivate var beginTimestamp: TimeInterval = 0
  fileprivate var elapsedTime: TimeInterval = 0
  
  fileprivate var gameState = GameState.ready
  
  // MARK: - IBOutlets
  @IBOutlet weak var clockLabel: UILabel!
  @IBOutlet weak var startLabel: UILabel!
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupPlayerView()
    prepareGame()
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    // First touch to start the game
    if gameState == .ready {
      startGame()
    }
    
    if let touchLocation = event?.allTouches?.first?.location(in: view) {
      // Move the player to the new position
      movePlayer(to: touchLocation)
      
      // Move all enemies to the new position to trace the player
      moveEnemies(to: touchLocation)
    }
  }
  
  // MARK: - Selectors
  func generateEnemy(timer: Timer) {
    // Generate an enemy with random position
    let screenEdge = ScreenEdge.init(rawValue: Int(arc4random_uniform(4)))
    let screenBounds = UIScreen.main.bounds
    var position: CGFloat = 0
    
    switch screenEdge! {
    case .left, .right:
      position = CGFloat(arc4random_uniform(UInt32(screenBounds.height)))
    case .top, .bottom:
      position = CGFloat(arc4random_uniform(UInt32(screenBounds.width)))
    }
    
    // Add the new enemy to the view
    let enemyView = UIView(frame: .zero)
    enemyView.bounds.size = CGSize(width: radius, height: radius)
    enemyView.backgroundColor = getRandomColor()
    
    switch screenEdge! {
    case .left:
      enemyView.center = CGPoint(x: 0, y: position)
    case .right:
      enemyView.center = CGPoint(x: screenBounds.width, y: position)
    case .top:
      enemyView.center = CGPoint(x: position, y: screenBounds.height)
    case .bottom:
      enemyView.center = CGPoint(x: position, y: 0)
    }
    
    view.addSubview(enemyView)
    
    // Start animation
    let duration = getEnemyDuration(enemyView: enemyView)
    let enemyAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear,
                                               animations: { [weak self] in
                                                if let strongSelf = self {
                                                  enemyView.center = strongSelf.playerView.center
                                                }
      }
    )
    enemyAnimator.startAnimation()
    enemyAnimators.append(enemyAnimator)
    enemyViews.append(enemyView)
  }
  
  func tick(sender: CADisplayLink) {
    updateCountUpTimer(timestamp: sender.timestamp)
    checkCollision()
  }
}

fileprivate extension ViewController {
  func setupPlayerView() {
    playerView.bounds.size = CGSize(width: radius * 2, height: radius * 2)
    playerView.layer.cornerRadius = radius
    playerView.backgroundColor = #colorLiteral(red: 0.7098039216, green: 0.4549019608, blue: 0.9607843137, alpha: 1)
    
    view.addSubview(playerView)
  }
  
  func startEnemyTimer() {
    enemyTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(generateEnemy(timer:)), userInfo: nil, repeats: true)
  }
  
  func stopEnemyTimer() {
    guard let enemyTimer = enemyTimer,
      enemyTimer.isValid else {
        return
    }
    enemyTimer.invalidate()
  }
  
  func startDisplayLink() {
    displayLink = CADisplayLink(target: self, selector: #selector(tick(sender:)))
    displayLink?.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
  }
  
  func stopDisplayLink() {
    displayLink?.isPaused = true
    displayLink?.remove(from: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
    displayLink = nil
  }
  
  func getRandomColor() -> UIColor {
    let index = arc4random_uniform(UInt32(colors.count))
    return colors[Int(index)]
  }
  
  func getEnemyDuration(enemyView: UIView) -> TimeInterval {
    let dx = playerView.center.x - enemyView.center.x
    let dy = playerView.center.y - enemyView.center.y
    return TimeInterval(sqrt(dx * dx + dy * dy) / enemySpeed)
  }
  
  func gameOver() {
    stopGame()
    displayGameOverAlert()
  }
  
  func stopGame() {
    stopEnemyTimer()
    stopDisplayLink()
    stopAnimators()
    gameState = .gameOver
  }
  
  func prepareGame() {
    removeEnemies()
    centerPlayerView()
    popPlayerView()
    startLabel.isHidden = false
    clockLabel.text = "00:00.000"
    gameState = .ready
  }
  
  func startGame() {
    startEnemyTimer()
    startDisplayLink()
    startLabel.isHidden = true
    beginTimestamp = 0
    gameState = .playing
  }
  
  func removeEnemies() {
    enemyViews.forEach {
      $0.removeFromSuperview()
    }
    enemyViews = []
  }
  
  func stopAnimators() {
    playerAnimator?.stopAnimation(true)
    playerAnimator = nil
    enemyAnimators.forEach {
      $0.stopAnimation(true)
    }
    enemyAnimators = []
  }
  
  func updateCountUpTimer(timestamp: TimeInterval) {
    if beginTimestamp == 0 {
      beginTimestamp = timestamp
    }
    elapsedTime = timestamp - beginTimestamp
    clockLabel.text = format(timeInterval: elapsedTime)
  }
  
  func format(timeInterval: TimeInterval) -> String {
    let interval = Int(timeInterval)
    let seconds = interval % 60
    let minutes = (interval / 60) % 60
    let milliseconds = Int(timeInterval * 1000) % 1000
    return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
  }
  
  func checkCollision() {
    enemyViews.forEach {
      guard let playerFrame = playerView.layer.presentation()?.frame,
        let enemyFrame = $0.layer.presentation()?.frame,
        playerFrame.intersects(enemyFrame) else {
          return
      }
      gameOver()
    }
  }
  
  func movePlayer(to touchLocation: CGPoint) {
    playerAnimator = UIViewPropertyAnimator(duration: playerAnimationDuration, dampingRatio: 0.5,
                                            animations: { [weak self] in
                                              self?.playerView.center = touchLocation
      }
    )
    playerAnimator?.startAnimation()
  }
  
  func moveEnemies(to touchLocation: CGPoint) {
    for (index, enemyView) in enemyViews.enumerated() {
      let duration = getEnemyDuration(enemyView: enemyView)
      enemyAnimators[index] = UIViewPropertyAnimator(duration: duration, curve: .linear,
                                                     animations: {
                                                      enemyView.center = touchLocation
        }
      )
      enemyAnimators[index].startAnimation()
    }
  }
  
  func displayGameOverAlert() {
    let (title, message) = getGameOverTitleAndMessage()
    let alert = UIAlertController(title: "Game Over", message: message, preferredStyle: .alert)
    let action = UIAlertAction(title: title, style: .default,
                               handler: { _ in
                                self.prepareGame()
      }
    )
    alert.addAction(action)
    self.present(alert, animated: true, completion: nil)
  }
  
  func getGameOverTitleAndMessage() -> (String, String) {
    let elapsedSeconds = Int(elapsedTime) % 60
    switch elapsedSeconds {
    case 0..<10: return ("I try again 😂", "Seriously, you need more practice 😒")
    case 10..<30: return ("Another go 😉", "No bad, you are getting there 😁")
    case 30..<60: return ("Play again 😉", "Very good 👍")
    default:
      return ("Off cause 😚", "Legend, olympic player, go 🇧🇷")
    }
  }
  
  func centerPlayerView() {
    // Place the player in the center of the screen.
    playerView.center = view.center
  }
  
  // Copy from IBAnimatable
  func popPlayerView() {
    let animation = CAKeyframeAnimation(keyPath: "transform.scale")
    animation.values = [0, 0.2, -0.2, 0.2, 0]
    animation.keyTimes = [0, 0.2, 0.4, 0.6, 0.8, 1]
    animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
    animation.duration = CFTimeInterval(0.7)
    animation.isAdditive = true
    animation.repeatCount = 1
    animation.beginTime = CACurrentMediaTime()
    playerView.layer.add(animation, forKey: "pop")
  }
  
}
