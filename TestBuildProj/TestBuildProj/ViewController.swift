//
//  ViewController.swift
//  TestBuildProj
//
//  Created by Michael Wasserman on 2019-05-29.
//  Copyright © 2019 Michael Wasserman. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    

    var storyboards = ["Project1","HappyDays"]
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Projects"
        tableView.tableFooterView = UIView()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return storyboards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LinkCell", for: indexPath)
        cell.textLabel?.text = storyboards[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: storyboards[indexPath.row], bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: storyboards[indexPath.row])
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
}

