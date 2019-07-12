//
//  WelcomeMessageTableViewCell.swift
//  Alamofire
//
//  Created by Ikarma Khan on 10/12/2018.
//

import UIKit
import SendBirdSDK

class WelcomeMessageTableViewCell: UITableViewCell {

    private var message: SBDUserMessage!
    private var prevMessage: SBDBaseMessage?
    private var displayNickname: Bool = true
    private var podBundle: Bundle!

    @IBOutlet weak var vwBackground: UIView!
    @IBOutlet weak var lblMessage: UILabel!

    
    var themeObject : ThemeObject! {
        didSet {
            configCell()
        }
    }
    
    public var containerBackgroundColour: UIColor = UIColor(red: 237.0/255.0, green: 237.0/255.0, blue: 237.0/255.0, alpha: 1.0)
    
    private func configCell () {
        self.lblMessage.text = self.themeObject?.welcomeMessage

        backgroundColor = .clear
        
        vwBackground.backgroundColor = self.themeObject?.primaryAccentColor
        vwBackground.alpha = 0.4
        vwBackground.layer.cornerRadius = 8.0
        vwBackground.layer.masksToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)        
        self.podBundle =  Bundle.bundleForXib(WelcomeMessageTableViewCell.self)
    }
    
    static func nib() -> UINib {
        let podBundle = Bundle.bundleForXib(WelcomeMessageTableViewCell.self)
        return UINib(nibName: String(describing: self), bundle: podBundle)
    }
    
    static func cellReuseIdentifier() -> String {
        return String(describing: self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
