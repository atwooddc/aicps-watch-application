//
//  DataCell.swift
//  QoE_companion
//
//  Created by David Atwood on 11/18/21.
//

import UIKit

class DataCell: UITableViewCell {
    
    @IBOutlet var id: UILabel!
    @IBOutlet var date: UILabel!
    @IBOutlet var dur: UILabel!

    static let identifier = "DataCell"
    
    static func nib() -> UINib {
        return UINib(nibName: "DataCell",
                     bundle: nil)
    }
    
    public func configure(with dataID: String, time: Date, duration: Int) {
        
        id.text = dataID
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: time)
        date.text = dateString
        
        let formatter2 = DateComponentsFormatter()
        formatter2.unitsStyle = .positional
        formatter2.zeroFormattingBehavior = .pad
        let components = DateComponents(minute: Int(duration/60), second: (duration % 60))
        dur.text = formatter2.string(from: components)
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
