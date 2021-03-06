//
//  MoviesViewController.swift
//  Flicks
//
//  Created by Phạm Thanh Hùng on 6/16/17.
//  Copyright © 2017 Phạm Thanh Hùng. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var networkErrorLabel: UILabel!
    
    var refreshControl: UIRefreshControl!
    
    var searchBar:UISearchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 290, height: 20))
    var searchActive : Bool = false

    var movies: [NSDictionary]?
    var searchMovies: [NSDictionary]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        //Initialize a UIRefreshControl
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(MoviesViewController.refreshControlAction), for: UIControlEvents.valueChanged)
        
        //add refresh control to table view
        tableView.insertSubview(refreshControl, at: 0)
        networkErrorLabel.isHidden = true
        
        searchBar.placeholder = "Search"
        let leftNavBarButton = UIBarButtonItem(customView:searchBar)
        self.navigationItem.leftBarButtonItem = leftNavBarButton
        
        fetchDataFromAPI()
    }
    
    func refreshControlAction() {
        fetchDataFromAPI()
    }
    
    func fetchDataFromAPI() {
        
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string: "https://api.themoviedb.org/3/movie/\("now_playing")?api_key=\(apiKey)")
        let request = URLRequest(
            url: url!,
            cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData,
            timeoutInterval: 10)
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate: nil,
            delegateQueue: OperationQueue.main
        )
        
        // Display HUD right before the request is made
        MBProgressHUD.showAdded(to: self.view, animated: true)

        let task: URLSessionDataTask =
            session.dataTask(with: request,
                             completionHandler: { (dataOrNil, response, error) in
                                if error != nil {
                                    self.networkErrorLabel.isHidden = false
                                    self.searchBar.isUserInteractionEnabled = false
                                } else if let data = dataOrNil {
                                    if let responseDictionary = try! JSONSerialization.jsonObject(
                                        with: data, options:[]) as? NSDictionary {
                                        print("response: \(responseDictionary)")
                                        
                                        // Hide HUD once the network request comes back (must be done on main UI thread)
                                        MBProgressHUD.hide(for: self.view, animated: true)
                                        
                                        self.movies = responseDictionary["results"] as? [NSDictionary]
                                        self.tableView.reloadData()
                                        
                                        self.networkErrorLabel.isHidden = true
                                        self.searchBar.isUserInteractionEnabled = true
                                        
                                        // Tell the refreshControl to stop spinning
                                        self.refreshControl.endRefreshing()
                                    }
                                }
            })
        task.resume()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPath(for: cell)
        
        var movie = NSDictionary()
        if searchActive && searchMovies != nil {
            movie = searchMovies![indexPath!.row]
        } else {
            
            movie = movies![indexPath!.row]
        }
        
        let detailViewController = segue.destination as! DetailsViewController
        detailViewController.movie = movie
    }
}

extension MoviesViewController: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var moviesCount = 0
        
        if searchActive {
            if let searchMovies = searchMovies {
                moviesCount = searchMovies.count
            }
        }
        else {
            if let movies = movies{
                moviesCount = movies.count
            }
        }
        
        return moviesCount
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        
        var movie = NSDictionary()
        if searchActive && searchMovies != nil {
            movie = searchMovies![indexPath.row]
        } else {
            movie = movies![indexPath.row]
        }
        
        let title = movie["title"] as! String
        cell.movieTitleLabel.text = title
        
        let overview = movie["overview"] as! String
        cell.movieOverviewLabel.text = overview
        
        let baseURL = "https://image.tmdb.org/t/p/w342"
        if let posterPath = movie["poster_path"] as? String {
            let imageURL = NSURL(string: baseURL + posterPath)
            let imageURLRequest = NSURLRequest(url: imageURL! as URL)
            cell.movieImageView.setImageWith(
                imageURLRequest as URLRequest,
                placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                    if imageResponse != nil {
                        cell.movieImageView.alpha = 0.0
                        cell.movieImageView.image = image
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            cell.movieImageView.alpha = 1.0
                        })
                    } else {
                        cell.movieImageView.image = image
                    }
            },
                failure: { (imageRequest, imageResponse, error) -> Void in
            })
        }
        
        let selectedBackground = UIView()
        selectedBackground.backgroundColor = UIColor.green
        cell.selectedBackgroundView = selectedBackground
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension MoviesViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        let searchPredicate = NSPredicate(format: "title CONTAINS[C] %@", searchText)
        searchMovies = (movies! as NSArray).filtered(using: searchPredicate) as? [NSDictionary]
        
        if(searchMovies?.count == 0){
            searchActive = false;
        } else {
            searchActive = true;
        }
        self.tableView.reloadData()
    }
}
