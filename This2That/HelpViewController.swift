//
//  HelpViewController.swift
//  Series
//
//  Created by Jeff Chimney on 2015-10-26.
//  Copyright © 2015 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class HelpViewController: UIViewController {
    
    // set up for the help page
    @IBOutlet var startWord: UILabel!
    @IBOutlet var endWord: UILabel!
    @IBOutlet var line1: UILabel!
    @IBOutlet var line2: UILabel!
    @IBOutlet var line3: UILabel!
    @IBOutlet var line4: UILabel!
    @IBOutlet var line5: UILabel!
    @IBOutlet var line6: UILabel!
    @IBOutlet var line7: UILabel!
    @IBOutlet var line8: UILabel!
    
    @IBOutlet var exampleWord: UITextField!
    @IBOutlet var gotItButton: UIButton!
    
    override func viewDidLoad() {
        
        self.view.backgroundColor = UIColorFromHex(rgbValue: 0x8FBAE6)
        line1.textColor = UIColorFromHex(rgbValue: 0x1F466E)
        line2.textColor = UIColorFromHex(rgbValue: 0x1F466E)
        line3.textColor = UIColorFromHex(rgbValue: 0x1F466E)
        line4.textColor = UIColorFromHex(rgbValue: 0x1F466E)
        line5.textColor = UIColorFromHex(rgbValue: 0x1F466E)
        line6.textColor = UIColorFromHex(rgbValue: 0x1F466E)
        line7.textColor = UIColorFromHex(rgbValue: 0x1F466E)
        line8.textColor = UIColorFromHex(rgbValue: 0x1F466E)
        startWord.textColor = UIColorFromHex(rgbValue: 0x1F466E)
        endWord.textColor = UIColorFromHex(rgbValue: 0x1F466E)
        exampleWord.backgroundColor = UIColorFromHex(rgbValue: 0xE0EEFD)
        
        gotItButton.backgroundColor = UIColorFromHex(rgbValue: 0x4E81B7)
        gotItButton.layer.cornerRadius = 5
        gotItButton.titleLabel!.textColor = UIColorFromHex(rgbValue: 0x93ACE7)
    }
    
    func UIColorFromHex(rgbValue:UInt32, alpha:Double=1.0)->UIColor {
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        
        return UIColor(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
    }
}
