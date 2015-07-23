//
//  ViewController.swift
//  OctoPrint
//
//  Created by Michael Teeuw on 22-07-15.
//  Copyright © 2015 Michael Teeuw. All rights reserved.
//

import UIKit

class OverviewTableViewController: UITableViewController {

    
    let sections = ["Version", "State", "Temperatures"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUI", name: octoPrintDidUpdateNotifiction, object: nil)

        OctoPrint.sharedInstance.updateAll()
        
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("updatePrinterData"), userInfo: nil, repeats: true)

        
        title = "OctoPrint"
    }
    
    
    func updatePrinterData() {
        OctoPrint.sharedInstance.updateAll()
    }

    func updateUI() {
        tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if OctoPrint.sharedInstance.temperatures.count == 0 {
            return sections.count - 1
        }
        return sections.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
            case 0:
                return 2
            
            case 1:
                return 1
            
            case 2:
                return OctoPrint.sharedInstance.temperatures.count
            
            default:
                return 0
        }
        
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
	override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		if section == tableView.numberOfSections - 1 {
			if let updated = OctoPrint.sharedInstance.updateTimeStamp {
				let formattedDate = NSDateFormatter.localizedStringFromDate(updated,dateStyle: NSDateFormatterStyle.MediumStyle, timeStyle: .MediumStyle)
				return "Last update: \(formattedDate)"
			}
		}
		return nil
	}

	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("BasicCell", forIndexPath: indexPath)
        
        let shortPath = (indexPath.section, indexPath.row)
        switch shortPath {
            case (0, 0):
                cell.textLabel?.text = "API"
                cell.detailTextLabel?.text = OctoPrint.sharedInstance.apiVersion
                cell.userInteractionEnabled = false
            
            case (0, 1):
                cell.textLabel?.text = "Server"
                cell.detailTextLabel?.text = OctoPrint.sharedInstance.serverVersion
                cell.userInteractionEnabled = false
            
            case (1, 0):
                cell.textLabel?.text = "Printer"
                cell.detailTextLabel?.text = OctoPrint.sharedInstance.printerStateText
                cell.userInteractionEnabled = false
            
            case (2,_):
                let cell = tableView.dequeueReusableCellWithIdentifier("TemperatureCell", forIndexPath: indexPath)
            
                var names:[String] = []
                for (name, _) in OctoPrint.sharedInstance.temperatures {
                    names.append(name)
                }
                
                if let temperature = OctoPrint.sharedInstance.temperatures[names[indexPath.row]] {
                    
                    cell.textLabel?.text = names[indexPath.row]
                    cell.detailTextLabel?.text = "\(temperature.actual.celciusString()) (\(temperature.target.celciusString()))"
                }
            
            
            default:
                break
        }
        
        return cell
		
	}
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 2 {
            performSegueWithIdentifier("ShowTemperatureSelector", sender: self)
        } else {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowTemperatureSelector" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let temperatureSelector = segue.destinationViewController as! TemperatureSelectorTableViewController
                
                var names:[String] = []
                for (name, _) in OctoPrint.sharedInstance.temperatures {
                    names.append(name)
                }
                
                temperatureSelector.toolName = names[indexPath.row]
                
            }
            
        }
    }
	
}



