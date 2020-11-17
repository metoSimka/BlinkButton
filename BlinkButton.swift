//
//  BlinkButton.swift
//  GreenBox
//
//  Created by metoSimka on 16.11.2020.
//  Copyright © 2020 BlackBricks. All rights reserved.
//

import Foundation
import UIKit

class CATextLayerYСentralized : CATextLayer {
    override func draw(in ctx: CGContext) {
        let height = self.bounds.size.height
        let fontSize = self.fontSize
        let yDiff = (height-fontSize)/2 - fontSize/10
        
        ctx.saveGState()
        ctx.translateBy(x: 0.0, y: yDiff)
        super.draw(in: ctx)
        ctx.restoreGState()
    }
}

class BlinkButton: UIButton {
    
    // MARK: - Public constants
    // MARK: - Public variables
    // MARK: - Private constants
    // MARK: - Private variables
    private var layersString: String = ""
    private var activeColor = #colorLiteral(red: 1, green: 0.5882352941, blue: 0.0862745098, alpha: 1).cgColor
    private var inactiveColor = UIColor.init(white: 1, alpha: 0.4).cgColor
    private var defaultFont = UIFont.boldSystemFont(ofSize: 14)
    private var defaultFontSize: CGFloat = 14
    
    private var textLayer: CATextLayerYСentralized?
    private var backgroundLayer: CALayer?
    private var blinkLayer: CALayer?

    private var defaultAnimationTime: TimeInterval = 0.2
    
    // Variables for blink calculations
    private var blinkLineDegree: CGFloat = 30
    private var blinkAnimationDuration: TimeInterval = 1.1
    private var blinkKeyTimes: [NSNumber] = [0, 0.8, 1]
    private var blinkLineWidth: CGFloat = 8
    private var blinkTimeInterval: TimeInterval = 5
    
    private var timer: Timer?

    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    init() {
        super.init(frame: CGRect.zero)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func layoutSubviews() {
        updateLayersSizes()
    }
    
    deinit {
        stopTimer()
    }

    // MARK: - Public methods
    
    public func restartTimer() -> Bool {
        guard let layer = blinkLayer else {
            return false
        }
        addRepeatableBlinkAnimation(blinkLayer: layer)
        return true
    }
    
    public func stopTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    public func configureAnimation(blinkLineDegree: CGFloat?,
                                   blinkAnimationDuration: TimeInterval?,
                                   blinkKeyTimes: [NSNumber]?,
                                   blinkLineWidth: CGFloat?,
                                   blinkTimeInterval: TimeInterval?) {
        if let degree = blinkLineDegree {
            self.blinkLineDegree = degree
        }
        
        if let duration = blinkAnimationDuration {
            self.blinkAnimationDuration = duration
        }
        
        if let keys = blinkKeyTimes {
            self.blinkKeyTimes = keys
        }
        
        if let lineWidth = blinkLineWidth {
            self.blinkLineWidth = lineWidth
        }
        
        if let blinkInterval = blinkTimeInterval {
            self.blinkTimeInterval = blinkInterval
        }
        _ = restartTimer()
    }
    
    public func configureUI(title: String? = nil,
                            activeColor: CGColor? = nil,
                            inactiveColor: CGColor? = nil,
                            defaultFontName: String? = "ProximaNova-Semibold",
                            defaultFontSize: CGFloat? = nil) {
        if let text = title {
            self.layersString = text
        }
        if let color = activeColor {
            self.activeColor = color
        }
        
        if let color = inactiveColor {
            self.inactiveColor = color
        }
        
        if let fontSize = defaultFontSize {
            self.defaultFontSize = fontSize
        }
        
        if let fontName = defaultFontName, let font = UIFont(name: fontName, size: self.defaultFontSize) {
            self.defaultFont = font
        }
 
        updateTextLayer()
    }

    public func updateBlinkState(isEnabled: Bool) {
        if isEnabled {
            setMaskTitleColor(activeColor, animated: true)
        } else {
            setMaskTitleColor(inactiveColor, animated: true)
        }
    }
    
    public func setFont(_ font: UIFont, size: CGFloat) {
        textLayer?.font = font
    }
    
    // MARK: - Private methods
    private func commonInit() {
        let mainLayer = setupBackgroundLayer()
        self.backgroundLayer = mainLayer
        self.textLayer = setupTextLayer(isMaskFor: mainLayer)
        self.blinkLayer = addBlinkLayer(for: mainLayer)
        updateBlinkState(isEnabled: self.isEnabled)
    }

    private func setupBackgroundLayer() -> CALayer {
        let layer = CALayer()
        self.layer.addSublayer(layer)
        layer.backgroundColor = Constants.Color.defaultOrange.cgColor
        return layer
    }
    
    private func setupTextLayer(isMaskFor backgroundLayer: CALayer) -> CATextLayerYСentralized {
        let textLayer = CATextLayerYСentralized()
        textLayer.frame = self.bounds
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.alignmentMode = .center
        backgroundLayer.mask = textLayer
        textLayer.masksToBounds = true
        updateTextLayer()
        return textLayer
    }
    
    private func setMaskTitleColor(_ color: CGColor, animated: Bool) {
        if animated {
            UIView.animate(withDuration: defaultAnimationTime) {
                self.backgroundLayer?.backgroundColor = color
            }
        } else {
            backgroundLayer?.backgroundColor = color
        }
    }
    
    private func addBlinkLayer(for mainLayer: CALayer) -> CALayer {
        let blinkLayer = CALayer()
        mainLayer.addSublayer(blinkLayer)
        blinkLayer.backgroundColor = UIColor.init(white: 1, alpha: 0.4).cgColor
        blinkLayer.frame = CGRect(x: -blinkLineWidth,
                                  y: 0,
                                  width: blinkLineWidth,
                                  height: self.bounds.size.height)
        
        let radians = blinkLineDegree * CGFloat.pi / 180
        blinkLayer.transform = CATransform3DRotate(CATransform3DIdentity, radians, 0, 0, 1)
        
        addRepeatableBlinkAnimation(blinkLayer: blinkLayer)
        return blinkLayer
    }
    
    private func addRepeatableBlinkAnimation(blinkLayer: CALayer) {
        stopTimer()
        self.timer = Timer.scheduledTimer(withTimeInterval: blinkTimeInterval, repeats: true) { (timer) in
            guard self.isEnabled else {
                return
            }
            let animation = CAKeyframeAnimation()
            animation.keyPath = "position.x"
            let fullWidth = self.bounds.size.width
            animation.values = [0, fullWidth*0.3, fullWidth + self.blinkLineWidth]
            animation.keyTimes = self.blinkKeyTimes
            animation.duration = self.blinkAnimationDuration
            animation.isAdditive = true
            blinkLayer.add(animation, forKey: "shake")
        }
    }
    
    private func updateLayersSizes() {
        backgroundLayer?.frame = self.bounds
        textLayer?.frame = self.bounds
    }
    
    private func updateTextLayer() {
        self.textLayer?.string = layersString
        self.textLayer?.font = defaultFont
        self.textLayer?.fontSize = defaultFontSize
    }
}
