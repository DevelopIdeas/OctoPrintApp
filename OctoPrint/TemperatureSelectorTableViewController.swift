//
//  TemperatureSelectorTableViewController.swift
//  OctoPrint
//
//  Created by Michael Teeuw on 23-07-15.
//  Copyright © 2015 Michael Teeuw. All rights reserved.
//

import UIKit

class TemperatureSelectorTableViewController: UITableViewController, TemperaturePickerTableViewCellDelegate {

    
    
    var heatedComponent:OPHeatedComponent!
    var targetTemperaturePickerCell:TemperaturePickerTableViewCell?
    var temperatureOffsetPickerCell:TemperaturePickerTableViewCell?
    
    
    let sections = ["Current","Set Target","Presets", "Set Offset"]


    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = heatedComponent.identifier

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUI", key: .DidUpdateComponent, object: heatedComponent)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUI", key: .DidUpdateSettings, object: heatedComponent)
        updateUI()
    }
    
   
    

    
    func updateUI() {
        tableView.reloadData()
    }


    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        switch section {
            case 0:
                return 3
            case 1:
                return 1
            case 2:
                return OPManager.sharedInstance.temperaturePresets.count
            case 3:
                return 1
            default:
                return 0
        }
      
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath == NSIndexPath(forRow: 0, inSection: 1) || indexPath == NSIndexPath(forRow: 0, inSection: 3)  {
            return 100
        }
        
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
       

        let shortPath = (indexPath.section, indexPath.row)
        switch shortPath {
            case (0, 0):
                let cell = tableView.dequeueReusableCellWithIdentifier("BasicCell", forIndexPath: indexPath)
                cell.textLabel?.text = "Actual"
                cell.detailTextLabel?.text =  heatedComponent.actualTemperature.celciusString()
                cell.userInteractionEnabled = false
                return cell
            
            case (0, 1):
                let cell = tableView.dequeueReusableCellWithIdentifier("BasicCell", forIndexPath: indexPath)
                cell.textLabel?.text = "Target"
                cell.detailTextLabel?.text = heatedComponent.targetTemperature.celciusString()
                cell.userInteractionEnabled = false
                return cell

            case (0, 2):
                let cell = tableView.dequeueReusableCellWithIdentifier("BasicCell", forIndexPath: indexPath)
                cell.textLabel?.text = "Offset"
                cell.detailTextLabel?.text = heatedComponent.temperatureOffset.celciusString()
                cell.userInteractionEnabled = false
                return cell
            
            case (1,_):
                 let cell = tableView.dequeueReusableCellWithIdentifier("TemperaturePickerCell", forIndexPath: indexPath) as! TemperaturePickerTableViewCell
                 cell.delegate = self
                 cell.maxTemp = 300
                 cell.stepSize = 5
                 cell.temperature = heatedComponent.targetTemperature
                 
                 targetTemperaturePickerCell = cell
            
                return cell
                 
            case (2,_):
                let cell = tableView.dequeueReusableCellWithIdentifier("BasicCell", forIndexPath: indexPath)
                cell.userInteractionEnabled = true
                
                let preset = OPManager.sharedInstance.temperaturePresets[indexPath.row]
                cell.textLabel?.text = preset.name
                
                if heatedComponent.componentType == .Bed {
                    cell.detailTextLabel?.text =  preset.bedTemperature.celciusString()
                } else {
                    cell.detailTextLabel?.text =  preset.extruderTemperature.celciusString()
                }
            
                return cell
            
            
            case (3,_):
                let cell = tableView.dequeueReusableCellWithIdentifier("TemperaturePickerCell", forIndexPath: indexPath) as! TemperaturePickerTableViewCell
                cell.delegate = self
                cell.minTemp = -50
                cell.maxTemp = 50
                cell.stepSize = 1
                cell.temperature = heatedComponent.temperatureOffset
                
                temperatureOffsetPickerCell = cell
                
                return cell
            
            default:
                
                    let cell = tableView.dequeueReusableCellWithIdentifier("BasicCell", forIndexPath: indexPath)
                    cell.textLabel?.text = "Unknow cell!"
                    return cell
            
        }
       
        
    }
    

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 2 {
            let preset = OPManager.sharedInstance.temperaturePresets[indexPath.row]
            let newTargetTemperature:Int
            if heatedComponent.componentType == .Bed {
                newTargetTemperature =  preset.bedTemperature
            } else {
                newTargetTemperature =  preset.extruderTemperature
            }
            
            setTargetTemperature(Float(newTargetTemperature))
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    
   
    func setTargetTemperature(target:Float) {
        heatedComponent.setTargetTemperature(target)
    }
    
    

}

// TemperaturePickerTableViewCellDelegate
extension TemperatureSelectorTableViewController {
    func temperaturePickerCellDidUpdate(temperaturePickerCell: TemperaturePickerTableViewCell) {
        
        if temperaturePickerCell == targetTemperaturePickerCell {
            self.setTargetTemperature(temperaturePickerCell.temperature)
        } else if temperaturePickerCell == temperatureOffsetPickerCell {
            heatedComponent.setTemperatureOffset(temperaturePickerCell.temperature)
        }
        
    }
}

