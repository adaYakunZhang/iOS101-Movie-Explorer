//
//  SearchViewController.swift
//  ios101-lab7-flix
//
//  Created by ESZYK on 11/17/23.
//

import UIKit
import Nuke

class SearchViewController: UIViewController, UISearchResultsUpdating {
    
    var searchResults = [Movie]()
    
    let searchController: UISearchController = {
        // Make sure you are using the correct storyboard name and controller identifier
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let resultsViewController = storyboard.instantiateViewController(withIdentifier: "ResultsViewController") as! ResultsViewController
        return UISearchController(searchResultsController: resultsViewController)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Search"
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text, !text.isEmpty else {
            return
        }
        searchMovies(query: text)
    }
    
    
    
    private func searchMovies(query: String) {
        let formattedQuery = query.replacingOccurrences(of: " ", with: "+")
        let apiKey = "031fd1f8d75bdda8ffbccedc7cc8dac8"
        guard let url = URL(string: "https://api.themoviedb.org/3/search/movie?query=\(formattedQuery)&api_key=\(apiKey)") else {
            return
        }
//        guard let url = URL(string: "https://api.themoviedb.org/3/search/movie?query=Jack+Reacher&api_key=031fd1f8d75bdda8ffbccedc7cc8dac8") else {
//            return
//        }
//    

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)

        let session = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("🚨 Request failed: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("🚨 Server Error: response: \(String(describing: response))")
                return
            }

            guard let data = data else {
                print("🚨 No data returned from request")
                return
            }

            do {
                // MARK: - jSONDecoder with custom date formatter
                let decoder = JSONDecoder()

                // Create a date formatter object
                let dateFormatter = DateFormatter()

                // Set the date formatter date format to match the the format of the date string we're trying to parse
                dateFormatter.dateFormat = "yyyy-MM-dd"

                // Tell the json decoder to use the custom date formatter when decoding dates
                decoder.dateDecodingStrategy = .formatted(dateFormatter)

                // Decode the JSON data into our custom `MovieFeed` model.
                let movieResponse = try decoder.decode(MovieFeed.self, from: data)

                // Access the array of movies
                let movies = movieResponse.results

                // Run any code that will update UI on the main thread.
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else {return}

                    // We have movies! Do something with them!
                    print("✅ SUCCESS!!! Fetched \(movies.count) movies")
                    
                    if let resultsVC = self.searchController.searchResultsController as? ResultsViewController {
                        resultsVC.movies = movies
                        resultsVC.resultsTableView.reloadData()
                    }
                }
            } catch {
                print("🚨 Error decoding JSON data into Movie Response: \(error.localizedDescription)")
                return
            }
        }

        // Don't forget to run the session!
        session.resume()
    }

}
