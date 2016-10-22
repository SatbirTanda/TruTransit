//
//  MTATableViewCell.swift
//  NYCTransit
//
//  Created by Satbir Tanda on 9/25/16.
//  Copyright © 2016 Satbir Tanda. All rights reserved.
//

import UIKit

class MTATableViewCell: UITableViewCell {
    
    @IBOutlet weak var timeLabelStackView: UIStackView!
    @IBOutlet weak var stopLabel: UILabel!  {
        didSet {
            stopLabel.textColor = UIColor.goldColor()
            stopLabel.adjustsFontSizeToFitWidth = true
        }
    }
    
    @IBOutlet weak var timeLabel: UILabel! {
        didSet {
            timeLabel.textColor = UIColor.goldColor()
            timeLabel.adjustsFontSizeToFitWidth = true
        }
    }
    @IBOutlet weak var secondTimeLabel: UILabel!  {
        didSet {
            secondTimeLabel.textColor = UIColor.goldColor()
            secondTimeLabel.adjustsFontSizeToFitWidth = true
        }
    }
    
    @IBOutlet weak var thirdTimeLabel: UILabel!  {
        didSet {
            thirdTimeLabel.textColor = UIColor.goldColor()
            thirdTimeLabel.adjustsFontSizeToFitWidth = true
        }
    }
    
    @IBOutlet weak var refreshButton: UIButton! {
        didSet {
            refreshButton.titleLabel?.adjustsFontSizeToFitWidth = true
        }
    }
    
    private var firstArrivalTime: String? {
        didSet {
            timeLabel.text = firstArrivalTime
        }
    }
    
    private var secondArrivalTime: String? {
        didSet {
            secondTimeLabel.text = secondArrivalTime
        }
    }
    
    private var thirdArrivalTime: String? {
        didSet {
            thirdTimeLabel.text = thirdArrivalTime
        }
    }

    
    @IBAction func refreshButtonTapped() {
        print("Tapped")
    }
    
    private var color = UIColor.blue
    
    var bus: Bus? {
        didSet {
            if bus != nil {
                stopLabel?.text = bus!.busStop.name
                if bus!.incomingBuses.count >= 3 {
                    setTimeLabel(label: &firstArrivalTime, expectedArrivalTime: bus!.incomingBuses[0].expectedArrivalTime)
                    setTimeLabel(label: &secondArrivalTime, expectedArrivalTime: bus!.incomingBuses[1].expectedArrivalTime)
                    setTimeLabel(label: &thirdArrivalTime, expectedArrivalTime: bus!.incomingBuses[2].expectedArrivalTime)
                } else if bus!.incomingBuses.count == 2 {
                    setTimeLabel(label: &firstArrivalTime, expectedArrivalTime: bus!.incomingBuses[0].expectedArrivalTime)
                    setTimeLabel(label: &secondArrivalTime, expectedArrivalTime: bus!.incomingBuses[1].expectedArrivalTime)
                    setTimeLabel(label: &thirdArrivalTime, expectedArrivalTime: nil)
                } else if bus!.incomingBuses.count == 1 {
                    setTimeLabel(label: &firstArrivalTime, expectedArrivalTime: bus!.incomingBuses[0].expectedArrivalTime)
                    setTimeLabel(label: &secondArrivalTime, expectedArrivalTime: nil)
                    setTimeLabel(label: &thirdArrivalTime, expectedArrivalTime: nil)
                } else {
                    setTimeLabel(label: &firstArrivalTime, expectedArrivalTime: nil)
                    setTimeLabel(label: &secondArrivalTime, expectedArrivalTime: nil)
                    setTimeLabel(label: &thirdArrivalTime, expectedArrivalTime: nil)
                }
            }
            color = UIColor.hexStringToUIColor(bus!.color)
            contentView.backgroundColor = color
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        let backgroundView = UIView(frame: contentView.frame)
        backgroundView.backgroundColor = color.darker() ?? UIColor.blue
        selectedBackgroundView = backgroundView
    }
    
    private func getTime(iso8601: String, inSeconds: Bool = false) -> Double? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX" // iso 8601
        
        if let arrivalTimeInSeconds = dateFormatter.date(from: iso8601)?.timeIntervalSinceNow {
            if inSeconds {
                return arrivalTimeInSeconds
            }
            return arrivalTimeInSeconds/60.0
        }
        
        return nil
    }
    
    private func setTimeLabel(label: inout String?, expectedArrivalTime: String?) {
        if expectedArrivalTime != nil {
            if let arrivalTimeInSeconds = getTime(iso8601: expectedArrivalTime!, inSeconds: true) {
                let arrivalTimeInMinutes = Int(arrivalTimeInSeconds/60.0)
                if arrivalTimeInSeconds < 30.0 {
                    label = "Less than 30 seconds"
                } else if arrivalTimeInMinutes < 1 {
                    label = "Less than 1 minute"
                } else if arrivalTimeInMinutes < 2 {
                    label = "\(arrivalTimeInMinutes) minute"
                } else {
                    label = "\(arrivalTimeInMinutes) minutes"
                }
            }
        } else {
            label =  "No Bus Yet"
        }
    }

}
