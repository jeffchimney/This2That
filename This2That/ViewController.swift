//
//  ViewController.swift
//  This2That
//
//  Created by Jeff Chimney on 2015-09-27.
//  Copyright (c) 2015 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData
import Social
import AVFoundation
import StoreKit
import GoogleMobileAds

class ViewController: UIViewController, UITextFieldDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver, GADBannerViewDelegate {
    //UI Elements
    @IBOutlet var scoreThisGame: UILabel!
    @IBOutlet var highScore: UILabel!
    @IBOutlet var endWord: UILabel!
    @IBOutlet var startWord: UILabel!
    @IBOutlet var currentWord: UITextField!
    @IBOutlet var nextWord: UIButton!
    @IBOutlet var storeButton: UIButton!
    @IBOutlet var helpButton: UIButton!
    //@IBOutlet var facebookButton: UIButton!
    //@IBOutlet var twitterButton: UIButton!
    
    var word_list = [String]()
    var successfulWords = [String]()
    var gameOver = false
    var boolArray = [false, false, false, false]
    var numberOfFreeSkips: Int! = 0
    var adCount: Int!
    var hasPaidToRemoveAds = false
    var keyboardHeight: CGFloat = 0
    
    // set up audio player and controls
    var audioPlayer = AVAudioPlayer()
    //@IBOutlet var muteButton: UIButton!
    var muted: DarwinBoolean!
    
    var randomWordsChosen: [String] = []
    
    ///////////////////////////////// STORE KIT \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    let defaults = UserDefaults.standard
    var product_id1: NSString?
    var product_id2: NSString?
    var currentlyBuying :Int?
    
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var bannerViewTopConstraint: NSLayoutConstraint!
    var isShowingAd = false
    
    override func viewDidLoad() {
        
        product_id1 = "skips"
        product_id2 = "turnOffAds"
        
        super.viewDidLoad()
        
        SKPaymentQueue.default().add(self)
        
        //Check if ads have been removed
        let purchased = defaults.value(forKey: "purchased")
        if purchased != nil {
            hasPaidToRemoveAds = true
        }
        else {
            hasPaidToRemoveAds = false
        }
        
        adCount = 0
        muted = false

        word_list = arrayFromContentsOfFileWithName(fileName: "word_list")!
        
        startWord.isUserInteractionEnabled = true
        endWord.isUserInteractionEnabled = true
        
        startWord.text = randomizeWord()
        endWord.text = randomizeWord()
        
        successfulWords.insert(startWord.text!, at: 0)

        currentWord.autocorrectionType = UITextAutocorrectionType.no
        currentWord.delegate = self
        
        //Set up view assets
        self.view.backgroundColor = UIColorFromHex(rgbValue: 0x8FBAE6)
        startWord.textColor = UIColorFromHex(rgbValue: 0x1F466E)
        endWord.textColor = UIColorFromHex(rgbValue: 0x1F466E)
        currentWord.backgroundColor = UIColorFromHex(rgbValue: 0xE0EEFD)
        scoreThisGame.textColor = UIColorFromHex(rgbValue: 0xE0EEFD)
        highScore.textColor = UIColorFromHex(rgbValue: 0x1F466E)
        nextWord.backgroundColor = UIColorFromHex(rgbValue: 0x4E81B7)
        nextWord.layer.cornerRadius = 5
        nextWord.titleLabel!.textColor = UIColorFromHex(rgbValue: 0x93ACE7)
        
        // social media button appearance
        helpButton.backgroundColor = UIColorFromHex(rgbValue: 0x4E81B7)
        helpButton.layer.cornerRadius = 5
        helpButton.titleLabel!.textColor = UIColorFromHex(rgbValue: 0x93ACE7)
        helpButton.layer.borderColor = UIColorFromHex(rgbValue: 0x4E81B7).cgColor
        
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.adSize = kGADAdSizeBanner
        bannerView.adUnitID = "ca-app-pub-4389649708318146/8092837312"
        
        if !hasPaidToRemoveAds {
            bannerView.load(GADRequest())
        } else {
            bannerViewTopConstraint.constant = -51
            UIView.animate(withDuration: 1, animations: { () -> Void in
                self.view.layoutIfNeeded()
            })
        }
    }
    
    // retrieve current and high scores when view appears
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //open keyboard
        currentWord.becomeFirstResponder()
        
        // load previous scores
        self.loadScores()
        if numberOfFreeSkips != 0 {
            nextWord.setTitle(String(numberOfFreeSkips), for: UIControlState.normal)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        currentWord.resignFirstResponder()
    }

    func arrayFromContentsOfFileWithName(fileName: String) -> [String]? {
        let path = Bundle.main.path(forResource: fileName, ofType: "txt")
        
        let content: String?
        do {
            content = try String(contentsOfFile:path!, encoding: String.Encoding.utf8)
        } catch _ {
            content = nil
        }
        return content!.components(separatedBy: "\n")
    }
    
    // used to pick start and target words
    func randomizeWord() -> String {
        let randomIndex = Int(arc4random_uniform(UInt32(word_list.count)))
        return word_list[randomIndex]
    }
    
    func randomizeWordFromText(seedWord: String) -> String {
        let seed_word_array = arrayFromContentsOfFileWithName(fileName: seedWord)!
        let randomizeIndex = Int(arc4random_uniform(UInt32(seed_word_array.count - 1)))
        return seed_word_array[randomizeIndex]
    }
    
    // hide keyboard if the game is over and check if word is valid
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        //increment adcounter
        if hasPaidToRemoveAds != true {
            adCount = adCount + 1
            if adCount >= 20 {
                if !isShowingAd {
                    bannerView.load(GADRequest())
                    adCount = 0
                }
            }
            print(adCount)
        }
    
        // check if word is in word_list array and play failure noise if not
        if word_list.contains(currentWord.text!) {
            checkDifference(word1: successfulWords.last!, word2: currentWord.text!)
        } else {
            playSoundWithName(fileName: "failure")
        }
    
        currentWord.text = ""
        if gameOver {
            self.view.endEditing(true)
        
        }
        return(false)
    }

    @IBAction func muteUnmute(sender: AnyObject) {
        if muted == false {
            muted = true
            //muteButton.setImage(UIImage(named: "muted.png") as UIImage!, for: UIControlState.normal)
        } else {
            muted = false
            //muteButton.setImage(UIImage(named: "unmuted.png") as UIImage!, for: UIControlState.normal)
        }
    }

    // check for one letter difference from last word
    func checkDifference(word1: String, word2: String) ->  Bool{
        //if text has too many characters play fail sound
        if word2.characters.count >= 4 {
            // play failure sound
            playSoundWithName(fileName: "failure")
        }
        
        // make sure text field isnt empty
        if word2.characters.count != 0 {
            boolArray = [false, false, false, false]
        
            var word1Array = [Character](word1.characters)
        
            var word2Array = [Character](word2.characters)
            // compare current word with text field string, placing true if the letters at each index match
            for index in 0...3 {
                // check words against eachother
                if word1Array[index] == word2Array[index] {
                    boolArray[index] = true
                }
            }

            // once boolArray has been filled, check to see if at least three of the letters were the same as the last word
            var numberOfTrues = 0
            for item in boolArray {
                if item {
                    numberOfTrues += 1
                }
            }
            if numberOfTrues >= 3 {
                successfulWords.append(word2)
                startWord.text = word2
                if startWord.text == endWord.text {
                    
                    // play give point sound
                    playSoundWithName(fileName: "givePoint")
                    
                    scoreThisGame.text = String(Int(scoreThisGame.text!)! + 1)
                    
                    self.startWord.text = self.randomizeWord()
                    if self.startWord.text == "imam" {
                        self.startWord.text = self.randomizeWord()
                    }
                    self.randomWordsChosen.append(self.startWord.text!)
                    var intermediateWord = self.randomizeWordFromText(seedWord: self.startWord.text!)
                    
                    var i = 0
                    while (i < 20) {
                        if self.randomWordsChosen.contains(intermediateWord) {
                            intermediateWord = self.randomizeWordFromText(seedWord: intermediateWord)
                        } else {
                            self.randomWordsChosen.append(intermediateWord)
                            intermediateWord = self.randomizeWordFromText(seedWord: intermediateWord)
                            i = i + 1
                        }
                    }
                    
                    self.endWord.text = intermediateWord
                    self.randomWordsChosen = []
                    
                    successfulWords.removeAll()
                    successfulWords.append(startWord.text!)
                    if Int(highScore.text!)! < Int(scoreThisGame.text!)! {
                        highScore.text = scoreThisGame.text
                    }
                } else {
                    // play successfulWordSound
                    playSoundWithName(fileName: "successfulWordChange")
                }
                // make sure the start and end words are saved every time the start word changes.
                // this avoids cheating by exitting out of the game and getting new words.
                self.saveScores(highScoreSave: highScore.text!, currentScoreSave: scoreThisGame.text!, currentNumberSkips: numberOfFreeSkips)
                
                return true
            } else {
                // play failure sound
                playSoundWithName(fileName: "failure")
                return false
            }
        } else {
            // play failure sound
            playSoundWithName(fileName: "failure")
            return false
        }
    }
    @IBAction func getNextWords(sender: UIButton) {
        // if hasnt bought free skips yet
        if numberOfFreeSkips == 0 {
            // play change word sound
            self.playSoundWithName(fileName: "successfulWordChange")
            
            self.successfulWords.removeAll()
            
            self.startWord.text = self.randomizeWord()
            self.randomWordsChosen.append(self.startWord.text!)
            var intermediateWord = self.randomizeWordFromText(seedWord: self.startWord.text!)
            
            var i = 0
            while (i < 30) {
                //if self.randomWordsChosen.contains(intermediateWord) {
                intermediateWord = self.randomizeWordFromText(seedWord: intermediateWord)
//                } else {
//                    self.randomWordsChosen.append(intermediateWord)
//                    intermediateWord = self.randomizeWordFromText(seedWord: intermediateWord)
                i = i + 1
                //}
            }
            
            self.endWord.text = intermediateWord
            self.randomWordsChosen = []
            
            self.successfulWords.removeAll()
            self.successfulWords.append(self.startWord.text!)
            if self.numberOfFreeSkips > 0 {
                self.numberOfFreeSkips = self.numberOfFreeSkips-1
                self.nextWord.setTitle(String(self.numberOfFreeSkips), for: UIControlState.normal)
                if self.numberOfFreeSkips == 0 {
                    self.nextWord.setTitle("Skip", for: UIControlState.normal)
                } else {
                    self.nextWord.setTitle(String(self.numberOfFreeSkips), for: UIControlState.normal)
                }
            } else {
                self.scoreThisGame.text! = "0"
                self.nextWord.setTitle("Skip", for: UIControlState.normal)
            }
            
            self.saveScores(highScoreSave: self.highScore.text!, currentScoreSave: self.scoreThisGame.text!, currentNumberSkips: self.numberOfFreeSkips)
        } else {
            // has bought free skips and still has some left, only choose new words and save
            // play change word sound
            playSoundWithName(fileName: "successfulWordChange")
            
            //increment adcounter
            if hasPaidToRemoveAds != true {
                adCount = adCount + 1
                if adCount >= 20 {
//                    showAd()
                    adCount = 0
                }
            }
            
            successfulWords.removeAll()
            
            startWord.text = randomizeWord()
            randomWordsChosen.append(startWord.text!)
            var intermediateWord = randomizeWordFromText(seedWord: startWord.text!)
            
            var i = 0
            while (i < 30) {
                //if randomWordsChosen.contains(intermediateWord) {
                intermediateWord = randomizeWordFromText(seedWord: intermediateWord)
                //} else {
                //    randomWordsChosen.append(intermediateWord)
                //    intermediateWord = randomizeWordFromText(seedWord: intermediateWord)
                i = i + 1
                //}
            }
            
            endWord.text = intermediateWord
            randomWordsChosen = []
            
            successfulWords.removeAll()
            successfulWords.append(self.startWord.text!)
            if numberOfFreeSkips > 0 {
                numberOfFreeSkips = numberOfFreeSkips-1
                nextWord.setTitle(String(numberOfFreeSkips), for: UIControlState.normal)
                if numberOfFreeSkips == 0 {
                    nextWord.setTitle("Skip", for: UIControlState.normal)
                } else {
                    nextWord.setTitle(String(numberOfFreeSkips), for: UIControlState.normal)
                }
            } else {
                scoreThisGame.text! = "0"
                nextWord.setTitle("Skip", for: UIControlState.normal)
            }
            
            saveScores(highScoreSave: highScore.text!, currentScoreSave: scoreThisGame.text!, currentNumberSkips: numberOfFreeSkips)

        }
    }
    
    // For defining colours with hex values
    func UIColorFromHex(rgbValue:UInt32, alpha:Double=1.0)->UIColor {
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        
        return UIColor(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
    }
    
    /////////////////////////// CORE DATA \\\\\\\\\\\\\\\\\\\\\\\\
    // saves scores and current start and target words
    func saveScores(highScoreSave: String, currentScoreSave: String, currentNumberSkips: Int) {
        let appDelegate =
        UIApplication.shared.delegate as! AppDelegate
        
        let managedContext = appDelegate.persistentContainer.viewContext

        // Set up storage for integer (score) values
        let entity =  NSEntityDescription.entity(forEntityName: "Scores",
                                                 in:managedContext)
        
        let newScore = NSManagedObject(entity: entity!,
            insertInto: managedContext)
        
        newScore.setValue(Int(highScoreSave), forKey: "highScore")
        newScore.setValue(Int(currentScoreSave), forKey: "currentScore")
        
        //set up storage for current and target words
        let wordEntity = NSEntityDescription.entity(forEntityName: "Words",
                                                    in:managedContext)
 
        let newWord = NSManagedObject(entity: wordEntity!,
            insertInto: managedContext)
        
        newWord.setValue(startWord.text!, forKey: "startWord")
        newWord.setValue(endWord.text!, forKey: "targetWord")
        
        //set up storage of number of skips the user has
        let skipEntity = NSEntityDescription.entity(forEntityName: "Skips",
                                                    in:managedContext)
        
        let newSkipsLabel = NSManagedObject(entity: skipEntity!,
            insertInto: managedContext)
        newSkipsLabel.setValue(currentNumberSkips, forKey: "skipButtonLabel")
        
        do {
            try managedContext.save()
        } catch _ as NSError  {
            //print("Could not save \(error), \(error.userInfo)")
        } catch {
            //print("Universal Catch")
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Scores")
        let fetchWordRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Words")
        let fetchSkipsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Skips")
        
        do {
            let results =
            try managedContext.fetch(fetchRequest)
            let wordResults =
            try managedContext.fetch(fetchWordRequest)
            let skipsResults = try managedContext.fetch(fetchSkipsRequest)
            
            let scores = results as! [NSManagedObject]
            let words = wordResults as! [NSManagedObject]
            let skips = skipsResults as! [NSManagedObject]
            
            for eachEntity in scores {
                // delete all that arent the most recent entry
                if eachEntity != newScore {
                     managedContext.delete(eachEntity)
                }
            }
            for eachEntity in words {
                // delete all that arent the most recent entry
                if eachEntity != newWord {
                    managedContext.delete(eachEntity)
                }
            }
            for eachEntity in skips {
                // delete all that arent the most recent entry
                if eachEntity != newSkipsLabel {
                    managedContext.delete(eachEntity)
                }
            }
            try managedContext.save()
            
        } catch _ as NSError {
            //print("Could not fetch \(error), \(error.userInfo)")
        } catch {
            //print("Universal Catch")
        }
    }
    
    // loads scores and current start and target words
    func loadScores() {
        let appDelegate =
        UIApplication.shared.delegate as! AppDelegate
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Scores")
        // optional
        fetchRequest.returnsObjectsAsFaults = false
        
        let fetchWordRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Words")
        // optional
        fetchWordRequest.returnsObjectsAsFaults = false
        
        let fetchSkipsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Skips")
        // optional
        fetchSkipsRequest.returnsObjectsAsFaults = false
        
        do {
            let results =
            try managedContext.fetch(fetchRequest)
            let scores = results as! [NSManagedObject]
            for each in scores {
                highScore.text = String(describing: each.value(forKey: "highScore")!)
                scoreThisGame.text = String(describing: each.value(forKey: "currentScore")!)
            }
            let wordResults =
                try managedContext.fetch(fetchWordRequest)
            let words = wordResults as! [NSManagedObject]
            for each in words {
                startWord.text = String(describing: each.value(forKey: "startWord")!)
                successfulWords.removeAll()
                successfulWords.append(startWord.text!)
                endWord.text = String(describing: each.value(forKey: "targetWord")!)
            }
            let skipsResults =
            try managedContext.fetch(fetchSkipsRequest)
            let skips = skipsResults as! [NSManagedObject]
            for each in skips {
                numberOfFreeSkips = (each.value(forKey: "skipButtonLabel")! as? Int)!
            }
        } catch _ as NSError {
            //print("Could not fetch \(error), \(error.userInfo)")
        } catch {
            //print("Universal Catch")
        }
    }
    
    ////////////////// SOCIAL NETWORKING / HELP \\\\\\\\\\\\\\\\\\\\\\
    @IBAction func helpPushed(sender: AnyObject) {
        //print("Help button pressed, sent to Help View")
    }
    
    @IBAction func facebookButtonPressed(sender: AnyObject) {
        if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook) {
            let fbShare:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
            
            self.present(fbShare, animated: true, completion: nil)
            
        } else {
            let alert = UIAlertController(title: "Accounts", message: "Please login to a Facebook account to share.", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func twitterButtonPressed(sender: AnyObject) {
        if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter) {
            
            let tweetShare:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            tweetShare.setInitialText("Help! I'm trying to get from '" + startWord.text! + "' to '" + endWord.text! + "' on This2That!")
            
            self.present(tweetShare, animated: true, completion: nil)
            
        } else {
            
            let alert = UIAlertController(title: "Accounts", message: "Please login to a Twitter account to tweet.", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //////////////////////SOUND EFFECTS \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    
    func playSoundWithName(fileName: String) {
        let alertSound = NSURL(fileURLWithPath: Bundle.main.path(forResource: fileName, ofType: "mp3")!)
    
        var _:NSError?
    
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
            try AVAudioSession.sharedInstance().setActive(true)
            try audioPlayer = AVAudioPlayer(contentsOf: alertSound as URL)
            
            if fileName == "failure" {
                audioPlayer.volume = 0.25
            }
            
            audioPlayer.prepareToPlay()
            audioPlayer.play()
        } catch _ {
            
        }
    }
    
    ////////////////////////////////// AD FUNCTIONS \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        isShowingAd = true
        print("adViewDidReceiveAd")
        bannerView.alpha = 0
        view.addSubview(bannerView)
        bannerViewTopConstraint.constant = 0
        UIView.animate(withDuration: 1, animations: {
            bannerView.alpha = 1
            self.view.layoutIfNeeded()
        })
    }
    
    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        isShowingAd = false
        bannerViewTopConstraint.constant = -51
        UIView.animate(withDuration: 1, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Tells the delegate that a full screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }
    
    /// Tells the delegate that the full screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }
    
    /// Tells the delegate that the full screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewDidDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("adViewWillLeaveApplication")
    }
    
    @IBAction func helpButtonPushed(_ sender: Any) {
        
    }
    
    @IBAction func payForAds(sender: AnyObject) {
        let alertController = UIAlertController(title: "Store", message:
            "", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Disable Ads", style: UIAlertActionStyle.default,handler:{
            (alert: UIAlertAction!) in
            self.currentlyBuying = 2
            
            if (SKPaymentQueue.canMakePayments())
            {
                let productID:NSSet = NSSet(object: self.product_id2!);
                let productsRequest:SKProductsRequest = SKProductsRequest(productIdentifiers: productID as! Set<String>);
                productsRequest.delegate = self;
                productsRequest.start();
                //print("Fetching Products");
            }else{
                //print("can't make purchases");
            }
        }))
        alertController.addAction(UIAlertAction(title: "Two Free Skips", style: UIAlertActionStyle.default,handler:{
            (alert: UIAlertAction!) in
            self.currentlyBuying = 1
            
            if (SKPaymentQueue.canMakePayments()) {
                let productID:NSSet = NSSet(object: self.product_id1!);
                let productsRequest:SKProductsRequest = SKProductsRequest(productIdentifiers: productID as! Set<String>);
                productsRequest.delegate = self;
                productsRequest.start();
                //print("Fetching Products");
            }else{
                //print("can't make purchases");
            }
        }))
        alertController.addAction(UIAlertAction(title: "Restore Purchases", style: UIAlertActionStyle.default,handler:{
            (alert: UIAlertAction!) in
            if (SKPaymentQueue.canMakePayments()) {
                //print("restoring purchases")
                SKPaymentQueue.default().restoreCompletedTransactions()
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel ,handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
////////////////////////////////// STORE KIT \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    func buyProduct(product: SKProduct){
        //print("Sending the Payment Request to Apple");
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment);
        
    }
    
    func productsRequest (_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        let count : Int = response.products.count
        //print(count)
        if (count>0) {
            _ = response.products
            let selectedProduct: SKProduct = response.products[0] as SKProduct
            if (selectedProduct.productIdentifier == "turnOffAds")  {
                print(selectedProduct.localizedTitle)
                print(selectedProduct.localizedDescription)
                print(selectedProduct.price)
                buyProduct(product: selectedProduct);
            } else {
                print(selectedProduct.localizedTitle)
                print(selectedProduct.localizedDescription)
                print(selectedProduct.price)
                buyProduct(product: selectedProduct)
            }
        } else {
            //print("nothing")
        }
    }
    
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        //print("Error Fetching product information");
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])    {
        //print("Received Payment Transaction Response from Apple");
        
        for transaction:AnyObject in transactions {
            if let trans:SKPaymentTransaction = transaction as? SKPaymentTransaction{
                switch trans.transactionState {
                case .purchased:
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    if currentlyBuying == 2 {
                        //disable ads
                        defaults.set(true , forKey: "purchased")
                        hasPaidToRemoveAds = true
                        bannerView.isHidden = true
                        
                        bannerViewTopConstraint.constant = -51
                        UIView.animate(withDuration: 1, animations: { () -> Void in
                            self.view.layoutIfNeeded()
                        })
                        
                    } else {
                        //add free skips
                        self.numberOfFreeSkips = self.numberOfFreeSkips + 2
                        self.nextWord.setTitle(String(self.numberOfFreeSkips), for: UIControlState.normal)
                        self.saveScores(highScoreSave: self.highScore.text!, currentScoreSave: self.scoreThisGame.text!, currentNumberSkips: self.numberOfFreeSkips)
                    }
                    break;
                case .failed:
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    break;
                    
                case .restored:
                    SKPaymentQueue.default().restoreCompletedTransactions()
                    
                default:
                    break;
                }
            }
        }
    }
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
    }
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
    }
    func paymentQueue(_ queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload]) {
    }
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        //print("RestoreFinished")
        //disable ads
        defaults.set(true , forKey: "purchased")
        hasPaidToRemoveAds = true
        bannerView.isHidden = true
        
        bannerViewTopConstraint.constant = -51
        UIView.animate(withDuration: 1, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
}


