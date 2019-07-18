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
    
    private var drone: Drone? = nil
    private var stateRef: Ref<DeviceState>?
    
    private var selectedUid: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = 80
        
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let droneEntry = self.droneList?[indexPath.row] {
            drone = groundSdk.getDrone(uid: droneEntry.uid)
            self.selectedUid = droneEntry.uid
            if let drone = drone {
                self.stateRef = drone.getState { [weak self] state in
                    (self?.tableView.cellForRow(at: indexPath) as! DeviceCell).connectionState.text = state!.description
                    
                    if (state?.connectionState.rawValue)! == 2 {
                            self?.navigateToHud()
                    }
                }
            }

            if let connectionState = stateRef?.value?.connectionState {
                if connectionState == DeviceState.ConnectionState.disconnected {
                    if let drone = drone {
                        if drone.state.connectors.count > 0 {
                            connect(drone: drone, connector: drone.state.connectors[0])
                        }
                    }
                } else {
                    _ = drone?.disconnect()
                }
            }
        }
    }
    
    private func connect(drone: Drone, connector: DeviceConnector) {
        if drone.state.connectionStateCause == .badPassword {
            // ask for password
            let alert = UIAlertController(title: "Password", message: "", preferredStyle: .alert)
            alert.addTextField(configurationHandler: nil)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                if let password = alert.textFields?[0].text {
                    _ = drone.connect(connector: connector, password: password)
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            _ = drone.connect(connector: connector)
        }
    }
    
    private func navigateToHud() {
        if let drone = drone {
            if drone.getPilotingItf(PilotingItfs.manualCopter) != nil {
                performSegue(withIdentifier: "gotoHud", sender: self)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return droneList?.count ?? 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? HudViewController,
            let selectedUid = selectedUid {
            viewController.setDeviceUid(selectedUid)
        }
    }
}


@objc(DeviceCell)
private class DeviceCell: UITableViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var model: UILabel!
    @IBOutlet weak var uid: UILabel!
    @IBOutlet weak var connectionState: UILabel!
    @IBOutlet weak var connectors: UILabel!
}

