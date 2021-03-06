//
//  SearchViewController.swift
//  MyNetflix
//
//  Created by joonwon lee on 2020/04/02.
//  Copyright © 2020 com.joonwon. All rights reserved.
//

import UIKit
import Kingfisher
import AVFoundation

class SearchViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var resultCollectionView: UICollectionView!
    
    // 컬렉션 뷰에 띄워줄 Movie 객체들
    // 원래 MVVM 패턴에서는 뷰 모델을 통해 가져오는 게 좋지만 실습상 쉽게 하기 위해 그냥 여기에 넣기
    // 처음엔 검색한 게 없으니까 비어있음
    var movies: [Movie] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}

extension SearchViewController: UICollectionViewDataSource {
    // 몇 개 넘어오는지
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count
    }
    // 어떻게 표현할 건지
    // 우선, 커스텀 셀을 만들어야 함
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ResultCell", for: indexPath) as?
        ResultCell else {
            return UICollectionViewCell()
        }
        let movie = movies[indexPath.item]
        let url = URL(string: movie.thumbnailPath)!
        // cell.movieThumbnail.image = movie.thumbnailPath // imagePath가 String이라서 오류
        // imagePath(String)를 이미지로 만들기
        // => third-party 라이브러리를 사용해보자
        // SPM, Cocoa Pod, Carthage 등 세 가지 방법을 통해 가져올 수 있다 (여기선 SPM 사용)
        // King Fisher 사용
        cell.movieThumbnail.kf.setImage(with: url) // url로 이미지를 만들어준다
        return cell
    }
   
}

class ResultCell: UICollectionViewCell {
    @IBOutlet weak var movieThumbnail: UIImageView!
}

// 클릭했을 때의 반응!
extension SearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // movie
        // player vc
        // player + movie
        // presenting player vc
        let movie =  movies[indexPath.item]
        let url = URL(string: movie.previewURL)!
        let item = AVPlayerItem(url: url)
        
        let sb = UIStoryboard(name: "Player", bundle: nil)
        let vc = sb.instantiateViewController(identifier: "PlayerViewController") as! PlayerViewController
        vc.modalPresentationStyle = .fullScreen // 전체화면으로 띄워주기
       
        
        vc.player.replaceCurrentItem(with: item) // vc에 아이템 셋팅
        present(vc, animated: false, completion: nil)
    }
}
// 사이즈 정해주기
extension SearchViewController: UICollectionViewDelegateFlowLayout {
   func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let margin: CGFloat = 8
        let itemSpacing: CGFloat = 10
        
        // 너비 = (총 너비 - 양쪽의 마진 - 아이템 간의 간격*2) / 한 줄에 띄울 개수
        let width = (collectionView.bounds.width - margin*2 - itemSpacing*2) / 3
        let height = width * 10/7 // width와의 비율로 정해주기
        return CGSize(width: width, height: height)
    }
}

extension SearchViewController: UISearchBarDelegate {
   private func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        /* 검색 시작 */
        // 검색 후 키보드가 올라와 있을 때, 내려가게 처리
        dismissKeyboard()
        // 검색어가 있는지 확인 
        guard let searchTerm = searchBar.text, searchTerm.isEmpty == false else {return}
        // 네트워킹을 통한 검색
        // - 목표 : 서치텀을 가지고 네트워킹을 통해서 영화 검색
        // - [x] 검색 API 필요
        // - [x] 결과를 받아올 모델 Movie, Response 만들기
        // - 결과를 받와서, CollectionView로 표현해주기
        
        // 인스턴스를 생성하지 않고 메소드 호출해서 사용
        
        SearchAPI.search(searchTerm) { movies in
            // collectionView로 표현하기
            print("--> 몇 개 넘어왔는지 \(movies.count), 첫번째꺼 제목\(movies.first?.title)")
            
            // Crash 해결 : UI 만드는 API가 메인 스레드에서만 실행되게하기
            DispatchQueue.main.async {
                self.movies = movies
                self.resultCollectionView.reloadData()
            }
            
           
        }
        print("--> 검색어: \(searchTerm)")
    
    }
}

class SearchAPI {
    // 타입 메소드 : 인스턴스가 생성되지 않아도 가져다 쓸 수 있음 (해당type.method 이렇게 사용!) // @escaping : completion안에 있는 코드 블럭이 메소드 밖에서 실행될 수도 있다는 의미
    static func search(_ term: String, completion: @escaping ([Movie])-> Void) {
        // url Session을 이용해서 검색 네트워킹
        let session = URLSession(configuration: .default)
        
        // url
        // urlComponent를 이용해서 url을 구성한다
        var urlComponents = URLComponents(string: "https://itunes.apple.com/search?")!
        let mediaQuery = URLQueryItem(name: "media", value: "movie") // 미디어의 타입은 무비쪽!
        let entityQuery = URLQueryItem(name: "entity", value: "movie")
        let termQuery = URLQueryItem(name: "term", value: term) // 검색어의 타입은 메소드를 통해 들어온 파라미터
        
        urlComponents.queryItems?.append(mediaQuery)
        urlComponents.queryItems?.append(entityQuery)
        urlComponents.queryItems?.append(termQuery)
        let requestURL = urlComponents.url!
        
        // 실제로 네트워킹을 해줄 아이
        let dataTask = session.dataTask(with: requestURL) {data, response, error in
            let successRange = 200..<300 // 200이 succes 코드
            
            guard error == nil,
                let statusCode = (response as? HTTPURLResponse)?.statusCode,
                successRange.contains(statusCode) else {
                    return
                completion([])
            }
            guard let resultData = data else {
                completion([])
                return
            }
            
            // 검색 result
            let string = String(data: resultData, encoding: .utf8)
            
            let movies = SearchAPI.parseMovies(resultData)
            completion(movies)
        }
        dataTask.resume() // 작업 시작
    }
    static func parseMovies(_ data: Data) -> [Movie] {
        let decoder = JSONDecoder()
        do {
            let response = try decoder.decode(Response.self, from: data)
            let movies = response.movies
            return movies
            
        } catch let error {
            print("--> parsing error: \(error.localizedDescription)")
            return []
        }
    }
}

// 모델들
struct Response: Codable { // Codable :  json 데이터를 Object로 쉽게 파싱하기 위함
    let resultCount: Int
    let movies: [Movie] // Movie 구조체를 Codable하게 만들어줘야 가능
    
    // 프로퍼티의 이름과 json 데이터의 키를 맞춰주기
    enum CodingKeys: String, CodingKey {
        case resultCount
        case movies = "results" // 매핑하기
    }
    
    
}

struct Movie: Codable{
    let title: String
    let director: String
    let thumbnailPath: String
    let previewURL: String
    
    // 프로퍼티의 이름과 json 데이터의 키를 맞춰주기
    enum CodingKeys: String, CodingKey {
        case title = "trackName"
        case director = "artistName"
        case thumbnailPath = "artworkUrl100"
        case previewURL = "previewUrl"
    }
}
