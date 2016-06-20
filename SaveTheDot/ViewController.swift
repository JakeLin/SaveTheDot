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
  
  // MARK: - Private
  private var playerView = UIView(frame: .zero)
  private var playerAnimator: UIViewPropertyAnimator?
  
  private var enemyViews = [UIView]()
  private var enemyAnimators = [UIViewPropertyAnimator]()
  private var enemyTimer: Timer?

  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    setupPlayerView()
    startEnemyTimer()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let touchLocation = event?.allTouches()?.first?.location(in: view) {
      playerAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.5,
        animations: { [weak self] in
          self?.playerView.center = touchLocation
        }
      )
      playerAnimator?.startAnimation()
    }
  }
  
  func gerenateEnemy(timer: Timer) {
    // Gerenate an enemy with random position
    let screenEdge = ScreenEdge.init(rawValue: Int(arc4random_uniform(4)))
    let screenBounds = UIScreen.main().bounds
    var position: CGFloat = 0
    if screenEdge == .left || screenEdge == .right {
      position = CGFloat(arc4random_uniform(UInt32(screenBounds.height)))
    } else if screenEdge == .top || screenEdge == .bottom {
      position = CGFloat(arc4random_uniform(UInt32(screenBounds.width)))
    }
    
    // Compilation error, may be an Xcode bug
//    switch screenEdge {
//    case .left, .right:
//      position = CGFloat(arc4random_uniform(UInt32(screenBounds.height)))
//    case .top, .bottom:
//      position = CGFloat(arc4random_uniform(UInt32(screenBounds.width)))
//    }

    // Add the new enemy to the view
    let enemyView = UIView(frame: .zero)
    enemyView.bounds.size = CGSize(width: radius, height: radius)
    enemyView.backgroundColor = #colorLiteral(red: 0.9333333333, green: 0.5607843137, blue: 0.431372549, alpha: 1)
    if screenEdge == .left {
      enemyView.center = CGPoint(x: 0, y: position)
    } else if screenEdge == .right {
      enemyView.center = CGPoint(x: screenBounds.width, y: position)
    } else if screenEdge == .top {
      enemyView.center = CGPoint(x: position, y: screenBounds.height)
    } else if screenEdge == .bottom {
      enemyView.center = CGPoint(x: position, y: 0)
    }
    
    // Compilation error, may be an Xcode bug
//    switch screenEdge {
//    case .left:
//      enemyView.center = CGPoint(x: 0, y: position)
//    case .right:
//      enemyView.center = CGPoint(x: screenBounds.width, y: position)
//    case .top:
//      enemyView.center = CGPoint(x: position, y: screenBounds.height)
//    case .bottom:
//      enemyView.center = CGPoint(x: position, y: 0)
//    }
    enemyViews.append(enemyView)
    view.addSubview(enemyView)
    
    // Start animation
    let enemyAnimator = UIViewPropertyAnimator(duration: 0.5, curve: .linear,
      animations: { [weak self] in
        if let strongSelf = self {
          enemyView.center = strongSelf.playerView.center
        }
      }
    )
    enemyAnimator.startAnimation()
    enemyViews.append(enemyView)
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
}
