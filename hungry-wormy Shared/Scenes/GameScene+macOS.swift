//
//  GameScene+macOS.swift
//  hungry-worm iOS
//
//  Created by Astemir Eleev on 04/12/2018.
//  Copyright © 2018 Astemir Eleev. All rights reserved.
//

import Foundation
import SpriteKit

#if os(OSX)

import Carbon

/// Mouse-based event handling
extension GameScene {
    
    // MARK: - Properties
    
    static let downArrow = UInt16(kVK_DownArrow)
    static let leftArrow = UInt16(kVK_LeftArrow)
    static let rightArrow = UInt16(kVK_RightArrow)
    static let upArrow = UInt16(kVK_UpArrow)
    static let backSpace = UInt16(kVK_Space)
    static let escape = UInt16(kVK_Escape)
    
    // MARK: - Mouse handling overrides
    
    override func mouseDown(with event: NSEvent) {
        // Has not been implemented yet
        
        let location = event.location(in: self)
        let pauseNode = nodes(at: location).first { $0.name == pauseHudNode?.name ?? "Pause" }

        if let _ = pauseNode {
            toggleOverlayScene(for: .pause, shouldPause: true)
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        // Has not been implemented yet
    }
    
    override func mouseUp(with event: NSEvent) {
        // Has not been implemented yet
    }
    
    // MARK: - Keyboard handling
    
    override func keyDown(with event: NSEvent) {
        let keyCode = event.keyCode
        
        switch keyCode {
        case GameScene.leftArrow:
            wormy?.change(direction: .left)
        case GameScene.rightArrow:
            wormy?.change(direction: .right)
        case GameScene.upArrow:
            wormy?.change(direction: .up)
        case GameScene.downArrow:
            wormy?.change(direction: .down)
        case GameScene.escape:
            debugPrint("escape key was pressed")
            if lastOverlayType == nil || lastOverlayType == .pause {
                debugPrint("pause toggle is about to be called")
                toggleOverlayScene(for: .pause, shouldPause: true)
            }
        default:
            break
        }
    }
    
}
#endif
