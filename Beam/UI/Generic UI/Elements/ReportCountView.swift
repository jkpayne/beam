//
//  ReportCountView.swift
//  Beam
//
//  Created by Joel Payne on 10/19/18.
//  Copyright © 2018 Awkward. All rights reserved.
//
import UIKit

@IBDesignable
class ReportCountView: BeamView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }

    fileprivate func setupView() {
        self.textlabel.font = self.font

        self.addSubview(self.iconImageView)
        self.addSubview(self.textlabel)
    }

    override func displayModeDidChange() {
        super.displayModeDidChange()

        self.textlabel.textColor = DisplayModeValue(#colorLiteral(red: 1, green: 0.662745098, blue: 0.07843137255, alpha: 1), darkValue: #colorLiteral(red: 1, green: 0.662745098, blue: 0.07843137255, alpha: 1))
        self.iconImageView.tintColor = DisplayModeValue(#colorLiteral(red: 1, green: 0.662745098, blue: 0.07843137255, alpha: 1), darkValue: #colorLiteral(red: 1, green: 0.662745098, blue: 0.07843137255, alpha: 1))
    }

    var count: Int = 0 {
        didSet {
            self.textlabel.text = self.text()

            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
    }

    var font: UIFont = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular) {
        didSet {
            self.textlabel.font = self.font

            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
    }

    fileprivate let spacing: CGFloat = 4.0

    fileprivate let textlabel = UILabel()
    fileprivate let iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "report"))
        imageView.accessibilityIgnoresInvertColors = true
        return imageView
    }()

    func text() -> String {
        return "×\(self.count)"
    }

    override var intrinsicContentSize: CGSize {
        let labelSize = self.textlabel.intrinsicContentSize
        let iconSize = self.iconImageView.intrinsicContentSize

        var height = iconSize.height
        if labelSize.height > height {
            height = labelSize.height
        }
        let width = iconSize.width + self.spacing + labelSize.width
        return CGSize(width: ceil(width), height: ceil(height))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let labelSize = self.textlabel.intrinsicContentSize
        let iconSize = self.iconImageView.intrinsicContentSize

        var xPosition: CGFloat = 0

        let iconFrame = CGRect(origin: CGPoint(x: xPosition, y: self.bounds.midY - (iconSize.height / 2)), size: iconSize)
        self.iconImageView.frame = iconFrame

        xPosition += iconSize.width
        xPosition += self.spacing

        let labelFrame = CGRect(origin: CGPoint(x: xPosition, y: self.bounds.midY - (labelSize.height / 2)), size: labelSize)
        self.textlabel.frame = labelFrame
    }

}

