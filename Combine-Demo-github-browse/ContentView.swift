//
//  ContentView.swift
//  Combine-Demo-github-browse
//
//  Created by 程信傑 on 2022/12/22.
//

import Combine
import SwiftUI

struct ContentView: View {
    @StateObject private var searchModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            List($searchModel.repos) { $repo in
                let name = repo.name
                Text(name)
            }
            .searchable(text: $searchModel.searchText, placement: .navigationBarDrawer(displayMode: .automatic))
            .navigationTitle("Search")
//                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

class SearchViewModel: ObservableObject {
    @Published var repos: [GitRepo] = []
    @Published var searchText: String = ""
    private var cancellableSet = Set<AnyCancellable>()

    init() {
        $searchText
            .throttle(for: 0.5, scheduler: RunLoop.main, latest: false)
            .removeDuplicates()
            .flatMap { keyword in
                let baseURL = "https://api.github.com"
                let path = "/users/\(keyword)/repos"
                let url = URL(string: baseURL + path)
                let request = URLSession.shared.dataTaskPublisher(for: url!)
                return request
                    .tryMap { data, response in
                        guard let httpResponse = response as? HTTPURLResponse,
                              httpResponse.statusCode == 200 else { throw NetworkError.badRequest }
//                        print(String(decoding: data, as: UTF8.self))
                        return data
                    }
                    .decode(type: [GitRepo].self, decoder: JSONDecoder())
                    .print()
                    .catch { _ in
                        Empty<[GitRepo], Never>()
                    }
            }
            .receive(on: RunLoop.main)
            .assign(to: &$repos)
    }
}

enum NetworkError: Error {
    case badRequest
}

struct Owner: Codable {
    var name: String
    enum CodingKeys: String, CodingKey {
        case name = "login"
    }
}

struct GitRepo: Codable, Identifiable {
    var id: Int
    var name: String
    var owner: Owner
    var isPrivate: Bool
    var url: String
    enum CodingKeys: String, CodingKey {
        case id, name, owner, url
        case isPrivate = "private"
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
