//
//  FeedViewController.swift
//  ios101-lab6-flix
//

import UIKit
import Nuke


// Add table view data source conformance
class FeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    struct Section {
        let title: String
        var movies: [Movie]
        var isExpanded: Bool
    }
    // Add table view outlet
    @IBOutlet weak var tableView: UITableView!

    // Add property to store fetched movies array
    // private var movies: [Movie] = []
    private var sections: [Section] = [
        Section(title: "Upcoming", movies: [], isExpanded: false),
        Section(title: "Now Playing", movies: [], isExpanded: false),
        Section(title: "Top Rated", movies: [], isExpanded: false),
        Section(title: "Popular", movies: [], isExpanded: false)
    ]

    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.prefersLargeTitles = true

        view.addSubview(tableView)
        // Assign table view data source
        tableView.dataSource = self
        tableView.delegate = self
        
        fetchUpcomingMovies()
        fetchNowPlayingMovies()
        fetchTopRatedMovies()
        fetchPopularMovies()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // get the index path for the selected row
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            
            // Deselect the currently selected row
            tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        return section.isExpanded ? section.movies.count : 0
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
        var indexPaths = [IndexPath]()
        for row in sections[section].movies.indices {
            let indexPath = IndexPath(row: row, section: section)
            indexPaths.append(indexPath)
        }

        let isExpanded = sections[section].isExpanded
        sections[section].isExpanded = !isExpanded

        // button.setTitle(isExpanded ? "Expand" : "Collapse", for: .normal)

        if isExpanded {
            tableView.deleteRows(at: indexPaths, with: .fade)
        } else {
            tableView.insertRows(at: indexPaths, with: .fade)
        }
    }
    

    


//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // print("🍏 numberOfRowsInSection called with movies count: \(movies.count)")
//
//        // Return the number of rows for the table.
//        return movies.count
//    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Create, configure and return a table view cell for the given row (i.e. `indexPath.row`)

        // print("🍏 cellForRowAt called for row: \(indexPath.row)")

        // Get a reusable cell
        // Returns a reusable table-view cell object for the specified reuse identifier and adds it to the table. This helps to optimize table view performance as the app only needs to create enough cells to fill the screen and can reuse cells that scroll off the screen instead of creating new ones.
        // The identifier references the identifier you set for the cell previously in the storyboard.
        // The `dequeueReusableCell` method returns a regular `UITableViewCell` so we need to cast it as our custom cell (i.e. `as! MovieCell`) in order to access the custom properties you added to the cell.
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        // MARK: - Pass the selected movie to the Detail View Controller

        // Get the index path for the selected row.
        // `indexPathForSelectedRow` returns an optional `indexPath`, so we'll unwrap it with a guard.
        guard let selectedIndexPath = tableView.indexPathForSelectedRow else { return }
        let section = sections[selectedIndexPath.section]

        // Get the selected movie from the movies array using the selected index path's row
        let selectedMovie = section.movies[selectedIndexPath.row]

        // Get access to the detail view controller via the segue's destination. (guard to unwrap the optional)
        guard let detailViewController = segue.destination as? DetailViewController else { return }

        detailViewController.movie = selectedMovie
    }
    
    // Fetches a list of Upcoming movies from the TMDB API
    private func fetchUpcomingMovies() {

        let url = URL(string: "https://api.themoviedb.org/3/movie/upcoming?api_key=031fd1f8d75bdda8ffbccedc7cc8dac8&language=en-US&page=1")!

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)

        // ---
        // Create the URL Session to execute a network request given the above url in order to fetch our movie data.
        // https://developer.apple.com/documentation/foundation/url_loading_system/fetching_website_data_into_memory
        // ---
        let session = URLSession.shared.dataTask(with: request) { data, response, error in

            // Check for errors
            if let error = error {
                print("🚨 Request failed: \(error.localizedDescription)")
                return
            }

            // Check for server errors
            // Make sure the response is within the `200-299` range (the standard range for a successful response).
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("🚨 Server Error: response: \(String(describing: response))")
                return
            }

            // Check for data
            guard let data = data else {
                print("🚨 No data returned from request")
                return
            }

            // The JSONDecoder's decode function can throw an error. To handle any errors we can wrap it in a `do catch` block.
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

                    // We have movies! Do something with them!
                    print("✅ SUCCESS!!! Fetched \(movies.count) movies")

//                     Iterate over all movies and print out their details.
//                    for (index, movie) in movies.enumerated() {
//                        print("🍿 MOVIE \(index) ------------------")
//                        print("Title: \(movie.title)")
//                        print("Overview: \(movie.overview)")
//                    }

                    // MARK: - Update the movies property so we can access movie data anywhere in the view controller.
                    self?.sections[0].movies = movies
                    // self?.movies = movies
                    // print("🍏 Fetched and stored \(movies.count) movies")

                    // Prompt the table view to reload its data (i.e. call the data source methods again and re-render contents)
                    self?.tableView.reloadData()
                }
            } catch {
                print("🚨 Error decoding JSON data into Movie Response: \(error.localizedDescription)")
                return
            }
        }

        // Don't forget to run the session!
        session.resume()
    }


    // Fetches a list of Now Playing movies from the TMDB API
    private func fetchNowPlayingMovies() {

        // URL for the TMDB Get Popular movies endpoint: https://developers.themoviedb.org/3/movies/get-popular-movies
        let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing?api_key=031fd1f8d75bdda8ffbccedc7cc8dac8&language=en-US&page=1")!

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)

        // ---
        // Create the URL Session to execute a network request given the above url in order to fetch our movie data.
        // https://developer.apple.com/documentation/foundation/url_loading_system/fetching_website_data_into_memory
        // ---
        let session = URLSession.shared.dataTask(with: request) { data, response, error in

            // Check for errors
            if let error = error {
                print("🚨 Request failed: \(error.localizedDescription)")
                return
            }

            // Check for server errors
            // Make sure the response is within the `200-299` range (the standard range for a successful response).
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("🚨 Server Error: response: \(String(describing: response))")
                return
            }

            // Check for data
            guard let data = data else {
                print("🚨 No data returned from request")
                return
            }

            // The JSONDecoder's decode function can throw an error. To handle any errors we can wrap it in a `do catch` block.
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

                    // We have movies! Do something with them!
                    print("✅ SUCCESS!!! Fetched \(movies.count) movies")

                    // Iterate over all movies and print out their details.
//                    for (index, movie) in movies.enumerated() {
//                        print("🍿 MOVIE \(index) ------------------")
//                        print("Title: \(movie.title)")
//                        print("Overview: \(movie.overview)")
//                    }

                    // MARK: - Update the movies property so we can access movie data anywhere in the view controller.
                    self?.sections[1].movies = movies
                    // self?.movies = movies
                    // print("🍏 Fetched and stored \(movies.count) movies")

                    // Prompt the table view to reload its data (i.e. call the data source methods again and re-render contents)
                    self?.tableView.reloadData()
                }
            } catch {
                print("🚨 Error decoding JSON data into Movie Response: \(error.localizedDescription)")
                return
            }
        }

        // Don't forget to run the session!
        session.resume()
    }


    // Fetches a list of Top Rated movies from the TMDB API
    private func fetchTopRatedMovies() {

        // URL for the TMDB Get Popular movies endpoint: https://developers.themoviedb.org/3/movies/get-popular-movies
        let url = URL(string: "https://api.themoviedb.org/3/movie/top_rated?api_key=031fd1f8d75bdda8ffbccedc7cc8dac8&language=en-US&page=1")!

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)

        // ---
        // Create the URL Session to execute a network request given the above url in order to fetch our movie data.
        // https://developer.apple.com/documentation/foundation/url_loading_system/fetching_website_data_into_memory
        // ---
        let session = URLSession.shared.dataTask(with: request) { data, response, error in

            // Check for errors
            if let error = error {
                print("🚨 Request failed: \(error.localizedDescription)")
                return
            }

            // Check for server errors
            // Make sure the response is within the `200-299` range (the standard range for a successful response).
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("🚨 Server Error: response: \(String(describing: response))")
                return
            }

            // Check for data
            guard let data = data else {
                print("🚨 No data returned from request")
                return
            }

            // The JSONDecoder's decode function can throw an error. To handle any errors we can wrap it in a `do catch` block.
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

                    // We have movies! Do something with them!
                    print("✅ SUCCESS!!! Fetched \(movies.count) movies")

                    // Iterate over all movies and print out their details.
//                    for (index, movie) in movies.enumerated() {
//                        print("🍿 MOVIE \(index) ------------------")
//                        print("Title: \(movie.title)")
//                        print("Overview: \(movie.overview)")
//                    }

                    // MARK: - Update the movies property so we can access movie data anywhere in the view controller.
                    self?.sections[2].movies = movies
                    // self?.movies = movies
                    // print("🍏 Fetched and stored \(movies.count) movies")

                    // Prompt the table view to reload its data (i.e. call the data source methods again and re-render contents)
                    self?.tableView.reloadData()
                }
            } catch {
                print("🚨 Error decoding JSON data into Movie Response: \(error.localizedDescription)")
                return
            }
        }

        // Don't forget to run the session!
        session.resume()
    }



    // Fetches a list of popular movies from the TMDB API
    private func fetchPopularMovies() {

        // URL for the TMDB Get Popular movies endpoint: https://developers.themoviedb.org/3/movies/get-popular-movies
        let url = URL(string: "https://api.themoviedb.org/3/movie/popular?api_key=031fd1f8d75bdda8ffbccedc7cc8dac8&language=en-US&page=1")!

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)

        // ---
        // Create the URL Session to execute a network request given the above url in order to fetch our movie data.
        // https://developer.apple.com/documentation/foundation/url_loading_system/fetching_website_data_into_memory
        // ---
        let session = URLSession.shared.dataTask(with: request) { data, response, error in

            // Check for errors
            if let error = error {
                print("🚨 Request failed: \(error.localizedDescription)")
                return
            }

            // Check for server errors
            // Make sure the response is within the `200-299` range (the standard range for a successful response).
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("🚨 Server Error: response: \(String(describing: response))")
                return
            }

            // Check for data
            guard let data = data else {
                print("🚨 No data returned from request")
                return
            }

            // The JSONDecoder's decode function can throw an error. To handle any errors we can wrap it in a `do catch` block.
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

                    // We have movies! Do something with them!
                    print("✅ SUCCESS!!! Fetched \(movies.count) movies")

                    // Iterate over all movies and print out their details.
//                    for (index, movie) in movies.enumerated() {
//                        print("🍿 MOVIE \(index) ------------------")
//                        print("Title: \(movie.title)")
//                        print("Overview: \(movie.overview)")
//                    }

                    // MARK: - Update the movies property so we can access movie data anywhere in the view controller.
                    self?.sections[3].movies = movies
                    // self?.movies = movies
                    // print("🍏 Fetched and stored \(movies.count) movies")

                    // Prompt the table view to reload its data (i.e. call the data source methods again and re-render contents)
                    self?.tableView.reloadData()
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
