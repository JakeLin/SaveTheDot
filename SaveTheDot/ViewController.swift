//
//  ViewController.swift
//  SaveTheDot
//
//  Created by Jake Lin on 6/18/16.
//  Copyright © 2016 Jake Lin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  enum ScreenEdge: Int {
    case top = 0
    case right = 1
    case bottom = 2
    case left = 3
  }
  
  // MARK: - Configurations
  private let radius: CGFloat = 10
  private let playerAnimationDuration = 5.0
  private let enemySpeed: CGFloat = 60 // points per second
  private let colors = [#colorLiteral(red: 0.08235294118, green: 0.6980392157, blue: 0.5411764706, alpha: 1), #colorLiteral(red: 0.07058823529, green: 0.5725490196, blue: 0.4470588235, alpha: 1), #colorLiteral(red: 0.9333333333, green: 0.7333333333, blue: 0, alpha: 1), #colorLiteral(red: 0.9411764706, green: 0.5450980392, blue: 0, alpha: 1), #colorLiteral(red: 0.1411764706, green: 0.7803921569, blue: 0.3529411765, alpha: 1), #colorLiteral(red: 0.1176470588, green: 0.6431372549, blue: 0.2941176471, alpha: 1), #colorLiteral(red: 0.8784313725, green: 0.4156862745, blue: 0.03921568627, alpha: 1), #colorLiteral(red: 0.7882352941, green: 0.2470588235, blue: 0, alpha: 1), #colorLiteral(red: 0.1490196078, green: 0.5098039216, blue: 0.8352941176, alpha: 1), #colorLiteral(red: 0.1137254902, green: 0.4156862745, blue: 0.6784313725, alpha: 1), #colorLiteral(red: 0.8823529412, green: 0.2, blue: 0.1607843137, alpha: 1), #colorLiteral(red: 0.7019607843, green: 0.1411764706, blue: 0.1098039216, alpha: 1), #colorLiteral(red: 0.537254902, green: 0.2352941176, blue: 0.662745098, alpha: 1), #colorLiteral(red: 0.4823529412, green: 0.1490196078, blue: 0.6235294118, alpha: 1), #colorLiteral(red: 0.6862745098, green: 0.7137254902, blue: 0.7333333333, alpha: 1), #colorLiteral(red: 0.1529411765, green: 0.2196078431, blue: 0.2980392157, alpha: 1), #colorLiteral(red: 0.1294117647, green: 0.1843137255, blue: 0.2470588235, alpha: 1), #colorLiteral(red: 0.5137254902, green: 0.5843137255, blue: 0.5843137255, alpha: 1), #colorLiteral(red: 0.4235294118, green: 0.4745098039, blue: 0.4784313725, alpha: 1)]
  
  // MARK: - Private
  private var playerView = UIView(frame: .zero)
  private var playerAnimator: UIViewPropertyAnimator?
  
  private var enemyViews = [UIView]()
  private var enemyAnimators = [UIViewPropertyAnimator]()
  private var enemyTimer: Timer?
  
  private var displayLink: CADisplayLink?
  private var beginTimestamp: TimeInterval = 0

  @IBOutlet weak var clock: UILabel!
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupPlayerView()
    startEnemyTimer()
    startDisplayLink()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let touchLocation = event?.allTouches()?.first?.location(in: view) {
      // Move the player to the new position
      playerAnimator = UIViewPropertyAnimator(duration: playerAnimationDuration, dampingRatio: 0.5,
        animations: { [weak self] in
          self?.playerView.center = touchLocation
        }
      )
      playerAnimator?.startAnimation()
      
      // Move all enemies to the new position after a delay
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
  }
  
  func gerenateEnemy(timer: Timer) {
    // Gerenate an enemy with random position
    let screenEdge = ScreenEdge.init(rawValue: Int(arc4random_uniform(4)))
    let screenBounds = UIScreen.main().bounds
    var position: CGFloat = 0
    
    // May be an Xcode bug, can use `switch` here, it will have an compilation error.
    if screenEdge == .left || screenEdge == .right {
      position = CGFloat(arc4random_uniform(UInt32(screenBounds.height)))
    } else if screenEdge == .top || screenEdge == .bottom {
      position = CGFloat(arc4random_uniform(UInt32(screenBounds.width)))
    }

    // Add the new enemy to the view
    let enemyView = UIView(frame: .zero)
    enemyView.bounds.size = CGSize(width: radius, height: radius)
    enemyView.backgroundColor = getRandomColor()
    if screenEdge == .left {
      enemyView.center = CGPoint(x: 0, y: position)
    } else if screenEdge == .right {
      enemyView.center = CGPoint(x: screenBounds.width, y: position)
    } else if screenEdge == .top {
      enemyView.center = CGPoint(x: position, y: screenBounds.height)
    } else if screenEdge == .bottom {
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
    // Update the count up timer
    if beginTimestamp == 0 {
      beginTimestamp = sender.timestamp
    }
    let elapsedTime = sender.timestamp - beginTimestamp
    clock.text = format(timeInterval: elapsedTime)
    
    
    //
  }
}

private extension ViewController {
  func setupPlayerView() {
    // Place the player in the center of the screen.
    let screenBounds = UIScreen.main().bounds
    let center = CGPoint(x: screenBounds.width/2, y: screenBounds.height/2)
    
    playerView.bounds.size = CGSize(width: radius * 2, height: radius * 2)
    playerView.center = center
    playerView.layer.cornerRadius = radius
    playerView.backgroundColor = #colorLiteral(red: 0.7098039216, green: 0.4549019608, blue: 0.9607843137, alpha: 1)
    view.addSubview(playerView)
  }
  
  func startEnemyTimer() {
    enemyTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(gerenateEnemy(timer:)), userInfo: nil, repeats: true)
  }
  
  func stopEnemyTimer() {
    if let enemyTimer = enemyTimer where enemyTimer.isValid {
      enemyTimer.invalidate()
    }
  }
  
  func startDisplayLink() {
    displayLink = CADisplayLink(target: self, selector: #selector(tick(sender:)))
    displayLink?.add(to: RunLoop.main(), forMode: RunLoopMode.defaultRunLoopMode.rawValue)
  }
  
  func stopDisplayLink() {
    displayLink?.isPaused = true
    displayLink?.remove(from: RunLoop.main(), forMode: RunLoopMode.defaultRunLoopMode.rawValue)
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
  
  func format(timeInterval: TimeInterval) -> String {
    let interval = Int(timeInterval)
    let seconds = interval % 60
    let minutes = (interval / 60) % 60
    let milliseconds = Int(timeInterval * 1000) % 1000
    return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
  }
}
