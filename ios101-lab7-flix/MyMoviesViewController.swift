//
//  FavoritesViewController.swift
//  ios101-lab7-flix
//

import UIKit
import Nuke

class FavoritesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    struct Section {
        let title: String
        var movies: [Movie]
        var isExpanded: Bool
    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyFavoritesLabel: UILabel!

    // var favoriteMovies: [Movie] = []
    private var sections: [Section] = [
        Section(title: "Favorites", movies: [], isExpanded: false),
        Section(title: "Willing to Watch", movies: [], isExpanded: false),
        Section(title: "Watched", movies: [], isExpanded: false)
    ]


    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.dataSource = self
        tableView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Anything in the defer call is guaranteed to happen last
        defer {
            // Show the "Empty Favorites" label if there are no favorite movies
            emptyFavoritesLabel.isHidden = !sections.isEmpty
        }

        // TODO: Get favorite movies and display in table view
        // Get favorite movies and display in table view
        // 1. Get the array of favorite movies
        // 2. Set the favoriteMovies property so the table view data source methods will have access to latest favorite movies.
        // 3. Reload the table view
        // ------
        let favoriteMovies = Movie.getMovies(forKey: Movie.favoritesKey) // Movies marked as favorites
        let willingToWatchMovies = Movie.getMovies(forKey: Movie.willsKey) // Example key, replace with actual logic
        let watchedMovies = Movie.getMovies(forKey: Movie.watchedKey) // Example key, replace with actual logic

        // Assign movies to corresponding sections
        sections[0].movies = favoriteMovies
        sections[1].movies = willingToWatchMovies
        sections[2].movies = watchedMovies

        // Reload the table view on the main thread
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        return section.isExpanded ? section.movies.count : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell

        // Get the movie associated table view row
        let movie = sections[indexPath.section].movies[indexPath.row]

        // Configure the cell (i.e. update UI elements like labels, image views, etc.)

        // Unwrap the optional poster path
        if let posterPath = movie.posterPath,

            // Create a url by appending the poster path to the base url. https://developers.themoviedb.org/3/getting-started/images
           let imageUrl = URL(string: "https://image.tmdb.org/t/p/w500" + posterPath) {

            // Use the Nuke library's load image function to (async) fetch and load the image from the image url.
            Nuke.loadImage(with: imageUrl, into: cell.posterImageView)
        }

        // Set the text on the labels
        cell.titleLabel.text = movie.title
        cell.overviewLabel.text = movie.overview

        // Return the cell for use in the respective table view row
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let button = UIButton(type: .system)
        button.setTitle(sections[section].title, for: .normal)
        button.tag = section
        button.addTarget(self, action: #selector(handleExpandCollapse), for: .touchUpInside)
        return button
    }
    @objc private func handleExpandCollapse(button: UIButton) {
        let section = button.tag
        sections[section].isExpanded.toggle()
        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        // MARK: - Pass the selected movie to the Detail View Controller

        // Get the index path for the selected row.
        // `indexPathForSelectedRow` returns an optional `indexPath`, so we'll unwrap it with a guard.
        guard let selectedIndexPath = tableView.indexPathForSelectedRow else { return }

        // Get the selected movie from the movies array using the selected index path's row
        let selectedMovie = sections[selectedIndexPath.section].movies[selectedIndexPath.row]

        // Get access to the detail view controller via the segue's destination. (guard to unwrap the optional)
        guard let detailViewController = segue.destination as? DetailViewController else { return }

        detailViewController.movie = selectedMovie
    }
}
