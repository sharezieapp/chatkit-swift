//
//  ViewController.swift
//  Test
//
//  Created by Grzegorz Kozłowski on 16/09/2019.
//  Copyright © 2019 Pusher Limited. All rights reserved.
//

import UIKit
import PusherChatkit

class ViewController: UITableViewController {
    
    var messageProvider = TestDataFactory.createMessageProvider()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.messageProvider.delegate = self
    }
    
    @IBAction func loadMore(sender: UIBarButtonItem) {
        self.messageProvider.fetchOlderMessages(numberOfMessages: 5)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messageProvider.numberOfAvailableMessages
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "testCell", for: indexPath)
        
        if let messageCell = cell as? MessageTableViewCell {
            let message = self.messageProvider.message(at: indexPath.row)
            
            if case let MessagePart.text(_, content) = message!.parts.first! {
                messageCell.messageLabel.text = content
            }
        }
        
        return cell
    }
    
}

extension ViewController: MessageProviderDelegate {
    
    func messageProvider(_ messageProvider: MessageProvider, didReceiveMessagesWithRange range: Range<Int>) {
        if range.endIndex == messageProvider.numberOfAvailableMessages {
            let indexPath = IndexPath(row: range.endIndex - 1, section: 0)
            
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: [indexPath], with: .fade)
            self.tableView.endUpdates()
            
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
        else {
            self.tableView.reloadData()
        }
    }
    
    func messageProvider(_ messageProvider: MessageProvider, didChangeMessageAtIndex index: Int, previousValue: Message) {
        self.tableView.beginUpdates()
        
        let indexPath = IndexPath(row: index, section: 0)
        self.tableView.reloadRows(at: [indexPath], with: .fade)
        
        self.tableView.endUpdates()
    }
    
    func messageProvider(_ messageProvider: MessageProvider, didDeleteMessageAtIndex index: Int, previousValue: Message) {
        self.tableView.beginUpdates()
        
        let indexPath = IndexPath(row: index, section: 0)
        self.tableView.deleteRows(at: [indexPath], with: .fade)
        
        self.tableView.endUpdates()
    }
    
    
}
