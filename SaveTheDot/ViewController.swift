//
//  ViewController.swift
//  SaveTheDot
//
//  Created by Jake Lin on 6/18/16.
//  Copyright © 2016 Jake Lin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  // MARK: - Configurations
  private let radius: CGFloat = 10
  
  // MARK: - Private
  private var playerView = UIView(frame: .zero)
  private var playerAnimator: UIViewPropertyAnimator?
    
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    setupPlayerView()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let touchLocation = event?.allTouches()?.first?.location(in: view) {
      playerAnimator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn, animations: { [weak self] in
          self?.playerView.center = touchLocation
        })
      playerAnimator?.startAnimation()
    }
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
}
