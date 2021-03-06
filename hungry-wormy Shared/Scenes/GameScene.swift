//
//  GameScene.swift
//  snake Shared
//
//  Created by Astemir Eleev on 24/10/2018.
//  Copyright © 2018 Astemir Eleev. All rights reserved.
//

import SpriteKit
#if os(iOS) || os(tvOS)
import device_kit
#endif

class GameScene: RoutingUtilityScene {

    // MARK: - Properties
    
    private(set) var lastOverlayType: OverlayType?
    private let overlayDuration: TimeInterval = 0.25
    
    /// The current scene overlay (if any) that is displayed over this scene.
    private var overlay: SceneOverlay? {
        didSet {
            // Clear the `buttons` in preparation for new buttons in the overlay.
            
            // Animate the old overlay out.
            oldValue?.backgroundNode.run(SKAction.fadeOut(withDuration: overlayDuration)) {
                oldValue?.backgroundNode.removeFromParent()
            }
            
            if let overlay = overlay, let scene = scene {
                overlay.backgroundNode.removeFromParent()
                scene.addChild(overlay.backgroundNode)
                
                // Animate the overlay in.
                overlay.backgroundNode.alpha = 1.0
                overlay.backgroundNode.run(SKAction.fadeIn(withDuration: overlayDuration))
                
                pauseHudNode?.run(SKAction.unhide())
            }
        }
    }
    
    private var markers: (fruits: [CGPoint], spawnPoints: [CGPoint], timeBombs: [CGPoint]) = ([], [], [])
    private(set) var wormy: WormNode?
    private var parser = TileLevel()
    
    fileprivate var fruitGenerator: FruitGenerator!
    private var spawnControllr: SpawnController!
    private var timeBombGenerator: TimeBombGenerator!
    
    lazy fileprivate var physicsContactController: PhysicsContactController = {
        guard let snake = self.wormy else {
            fatalError("Could not unwrap the required properties in order to initialize PhysicsContactController class")
        }
        return PhysicsContactController(worm: snake,
                                        fruitGenerator: fruitGenerator,
                                        timeBombGenerator: timeBombGenerator,
                                        scene: self,
                                        deathHandler: deathHandler,
                                        completionHandler: completionHandler)
    }()
    
    lazy fileprivate var completionHandler: () -> () = { [weak self] in
        self?.physicsWorld.contactDelegate = nil
        self?.toggleOverlayScene(for: .results)
    }
    
    lazy fileprivate var deathHandler: () -> () = { [weak self] in
        self?.wormy?.kill()
        self?.physicsContactController.worm = nil
        self?.wormy = nil
        
        self?.physicsWorld.contactDelegate = nil
        self?.toggleOverlayScene(for: .death)
    }
    
    lazy fileprivate var restartHandler: ()->() = { [ weak self ] in
        self?.createWorm()
        self?.physicsContactController.worm = self?.wormy
    }
    
    private var timeOfLastMove: TimeInterval = 0
    private(set) var timePerMove = 0.0

    class func newGameScene(named name: String) -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: name) as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
        
        return scene
    }
    
    var pauseHudNode: SKNode?
    
    // MARK: - Methods
    
    func setUpScene() {
        #if os(iOS) || os(tvOS)
        prepareSwipeGestureRecognizers()
        prepareHud()
        #endif
        
        pauseToggleDelegate = self
        restartToggleDelegate = self
        
        timePerMove = Double(userData?["timePerMove"] as? Float ?? 0.6)
        
        guard let wallsTileNode = scene?.childNode(withName: "Walls") as? SKTileMapNode, let markerTileNode = scene?.childNode(withName: "Markers") as? SKTileMapNode else {
            fatalError("Could not load Walls or Markers SKTileMapNode, the app cannot be futher executed")
        }
        markers = parser.parseMarkers(for: markerTileNode)

        fruitGenerator = FruitGenerator(spawnPoints: markers.fruits, zPosition: 20)
        timeBombGenerator = TimeBombGenerator(spawnPoints: markers.timeBombs)

        let walls = parser.parseWalls(for: wallsTileNode)
        walls.forEach { self.addChild($0) }
        
        spawnControllr = SpawnController()
        createWorm()
        
        physicsContactController.generateFruit()
        physicsContactController.generateTimeBomb()
    }
    
    override func didMove(to view: SKView) {
        launchReferenceAnimations()
        setUpScene()
    }
    
    override func update(_ currentTime: TimeInterval) {
        if (currentTime - timeOfLastMove) < timePerMove { return }
        
        wormy?.update()
        timeOfLastMove = currentTime
    }
    
    deinit {
        physicsContactController.worm = nil
        wormy?.kill()
        wormy = nil
    }
    
    // MARK: - Utils
    
    func createWorm() {
        let spawnPoint = spawnControllr.generate(outOf: markers.spawnPoints)
        
        wormy = WormNode(position: spawnPoint ?? .zero)
        wormy?.zPosition = 50
        addChild(wormy!)
        
        physicsWorld.contactDelegate = self
    }
    
    /// Prepares the HUD layout paddings for a particular scene size
    #if os(iOS) || os(tvOS)
    private func prepareHud() {
        pauseHudNode = scene?.childNode(withName: "//Pause")
        let height = (view?.frame.height ?? 1.0)
        var positionY: CGFloat
        let deviceType = UIDevice.current.deviceType
        
        switch deviceType { case .iPad, .iPad2, .iPad3, .iPad4, .iPadAir, .iPadAir2, .iPadMini, .iPadMini3, .iPadMini4, .iPadPro9Inch, .iPadPro11Inch, .iPadPro12Inch, .iPadPro10p5Inch, .iPadPro12p9Inch:
            positionY = height - height / 2.2
        default:
            positionY = height - 48
        }
        
        pauseHudNode?.position.y = positionY
        pauseHudNode?.position.x -= 48
    }
    #endif
    
    func toggleOverlayScene(for overlay: OverlayType, shouldPause: Bool = false) {
        lastOverlayType = overlay
        
        if let _ = self.overlay {
            if shouldPause {
                self.isPaused = false
            }
            self.overlay = nil
            return
        }
        
        if shouldPause {
            self.isPaused = true
        }

        let overlay = SceneOverlay(overlaySceneFileName: overlay.sceneName, zPosition: 1000)
        self.overlay = overlay
    }
}

// MARK: - Conformance to SKPhysicsContactDelegate protocol
extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        physicsContactController.didBeginPhysicsContact(contact)
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        physicsContactController.didEndPhysicsContact(contact)
    }
}

// MARK: - Conformance to PauseTogglable protocol
extension GameScene: PauseTogglable {
    func didTogglePause() {
        toggleOverlayScene(for: .pause, shouldPause: true)
    }
}

// MARK: - Conformance to Restarable protocol
extension GameScene: Restarable {
    
    var sceneToRestart: String {
        return (scene?.name)! 
    }
}
