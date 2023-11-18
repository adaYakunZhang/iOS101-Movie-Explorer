//
//  ResultsViewController.swift
//  ios101-lab7-flix
//
//  Created by ESZYK on 11/17/23.
//

import UIKit

class ResultsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)
        cell.textLabel?.text = movies[indexPath.row].title
        return cell
    }
    
    
    var movies: [Movie] = []

    @IBOutlet weak var resultsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resultsTableView.dataSource = self
        resultsTableView.delegate = self
        resultsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "ResultCell")
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let movie = movies[indexPath.row]
        performSegue(withIdentifier: "ShowDetailSegue", sender: movie)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetailSegue",
           let destination = segue.destination as? DetailViewController,
           let movie = sender as? Movie {
            destination.movie = movie
        }
    }

    

}

//class ResultsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
//    var movies: [Movie] = []
//    var tableView: UITableView!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupTableView()
//        tableView.register(ResultCell.self, forCellReuseIdentifier: "ResultCell")
//        tableView.dataSource = self
//        tableView.delegate = self
//    }
//    
//    private func setupTableView() {
//        tableView = UITableView(frame: view.bounds, style: .plain)
//        tableView.dataSource = self
//        view.addSubview(tableView)
//    }
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return movies.count
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath) as! ResultCell
//        let movie = movies[indexPath.row]
//        cell.titleLabel.text = movie.title
//        return cell
//    }
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let storyboard = UIStoryboard(name: "Main", bundle: nil) // Use your actual storyboard name
//        if let detailViewController = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController {
//            let selectedMovie = movies[indexPath.row]
//            detailViewController.movie = selectedMovie
//            self.navigationController?.pushViewController(detailViewController, animated: true)
//            print(selectedMovie.title)
//        }
//        
//    }
//}
