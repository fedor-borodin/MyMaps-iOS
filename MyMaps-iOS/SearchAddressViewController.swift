//
//  SearchAddressViewController.swift
//  MyMaps-iOS
//
//  Created by Admin on 22/05/2017.
//  Copyright © 2017 fborodin. All rights reserved.
//

import UIKit
import GooglePlaces

//class SearchAddressViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

class SearchAddressViewController: UIViewController {

//    @IBOutlet weak var searchAddressTextField: UITextField!
//    @IBOutlet weak var tableView: UITableView!
//    
//    var geocodingTasks = GeocodingTasks()
//    
//    
//    
//    // get number of rows
//    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 0 //itemsList.count
//    }
//    
//    // fill cells with data
//    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = UITableViewCell(style: .default, reuseIdentifier: "searchAddressCell")
//        
////        if indexPath.row < itemsList.count {
////            cell.textLabel?.text = itemsList[indexPath.row].title
////            cell.accessoryType = itemsList[indexPath.row].status ? .checkmark : .none
////        }
//        
//        return cell
//    }
//    
//    // touch the cell to check/uncheck
//    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
////        tableView.deselectRow(at: indexPath, animated: true)
////        
////        if indexPath.row < itemsList.count {
////            itemsList[indexPath.row].status = !itemsList[indexPath.row].status
////            
////            tableView.reloadRows(at: [indexPath], with: .automatic)
////            
////            do {
////                try itemsList.writeToPersistense()
////            } catch let error {
////                NSLog("Error writing to persistence: \(error)")
////            }
////        }
//    }
//
    override func viewDidLoad() {
        super.viewDidLoad()

        let acController = GMSAutocompleteViewController()
        acController.delegate = self
        present(acController, animated: true, completion: nil)
        
//        searchAddressTextField.delegate = self
//        
//        searchAddressTextField.becomeFirstResponder()
//        
        // Do any additional setup after loading the view.
    }
//
//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        //
//        return true
//    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

extension SearchAddressViewController: GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        NSLog("Place name: \(place.name)")
        NSLog("Place address: \(String(describing: place.formattedAddress))")
        NSLog("Place attributions: \(String(describing: place.attributions))")
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        NSLog("Error: \(error)")
        dismiss(animated: true, completion: nil)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        NSLog("Autocomplete was cancelled.")
        dismiss(animated: true, completion: nil)
    }
}
