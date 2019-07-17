//
//  ViewController.swift
//  ParrotDemo
//
//  Created by ian timmis on 7/16/19.
//  Copyright © 2019 RIIS. All rights reserved.
//

import UIKit
import GroundSdk

class HomeViewController: UITableViewController {
    
    private let groundSdk = GroundSdk()
    private var droneListRef: Ref<[DroneListEntry]>!
    private var droneList: [DroneListEntry]?
    
//    private var selectedUid: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = 100
        
        // This keeps our drone lists up to date in real time
        droneListRef = groundSdk.getDroneList(
            observer: { [unowned self] entryList in
                self.droneList = entryList
                self.tableView.reloadData()
        })
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DroneCell", for: indexPath)
        if let cell = cell as? DeviceCell {
            if let droneEntry =  self.droneList?[indexPath.row] {
                cell.name.text = droneEntry.name
                cell.uid.text = droneEntry.uid
                cell.model.text = droneEntry.model.description
                let state = droneEntry.state
                cell.connectionState.text =
                "\(state.connectionState.description)-\(state.connectionStateCause.description)"
            }
        }
        
        return cell
    }
    
//    ovecd rride func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if let droneEntry = self.droneList?[indexPath.row] {
//            selectedUid = droneEntry.uid
//            performSegue(withIdentifier: droneInfoSegue, sender: self)
//        }
//    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return droneList?.count ?? 0
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == droneInfoSegue ||  segue.identifier == rcInfoSegue {
//            if let viewController = segue.destination as? DeviceViewController,
//                let selectedUid = selectedUid {
//                viewController.setDeviceUid(selectedUid)
//            }
//        }
//    }
}


@objc(DeviceCell)
private class DeviceCell: UITableViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var model: UILabel!
    @IBOutlet weak var uid: UILabel!
    @IBOutlet weak var connectionState: UILabel!
    @IBOutlet weak var connectors: UILabel!
}

