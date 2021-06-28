//
//  SoundsManager.swift
//  Glarm
//
//  Created by Adam Wienconek on 17/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation
import UserNotifications
import AVFoundation

protocol SoundsManagerDelegate: AnyObject {
    func soundsManager(_ manager: SoundsManager, didBeginDownloading sound: Sound)
    func soundsManager(_ manager: SoundsManager, didDownload sound: Sound)
    func soundsManager(_ manager: SoundsManager, didEncounter error: Error)
}

enum SoundsDirectory: String, Directory {
    case files = "Sounds"
    case data = "SoundData"
    
    var searchPath: FileManager.SearchPathDirectory {
        switch self {
        case .files:
            return .libraryDirectory
        case .data:
            return .documentDirectory
        }
    }
}

class SoundsManager {
    
    private let fileManager = FileManager.default
    
    private lazy var soundUrls: [String: URL] = PlistReader.dictionary(from: PlistFile.sounds.rawValue) ?? [:]
    
    weak var delegate: SoundsManagerDelegate?
    
    private var downloadTask: URLSessionTask? {
        willSet {
            downloadTask?.cancel()
        } didSet {
            downloadTask?.resume()
        }
    }
    
    var didDownloadAllSounds: Bool {
        let contents = fileManager.contents(directory: SoundsDirectory.data) ?? []
        return contents.count == soundUrls.count
    }
    
    /**
     Array of local `Sound` files. Files contain local urls.
     */
    var downloadedSounds: [Sound] {
        let contents = fileManager.contents(directory: SoundsDirectory.data) ?? []
        let decoded = contents.compactMap { data in
            try? JSONDecoder().decode(Sound.self, from: data)
        }.filter { $0.isLocal }
        return [.default] + decoded
    }
    
    /**
     Array of `Sound` files available to download. Files contain remote urls.
     */
    var availableSounds: [Sound] {
        return soundUrls.map { name, url in
            return Sound(name: name, url: url)
        }.filter { sound in
            !self.downloadedSounds.contains(where: { $0.name == sound.name })
        }
    }
    
    func setSound(named name: String) {
        SoundsManager.selectedSoundName = name
    }
    
    //    func removeSound(_ sound: Sound) {
    //
    //    }
    
    func downloadSound(_ sound: Sound) {
        downloadTask = URLSession.shared.dataTask(with: sound.url) { data, response, error in
            if let error = error {
                self.delegate?.soundsManager(self, didEncounter: error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                    return
            }
            guard let data = data,
                  let fileUrl = self.fileManager.save(file: data, named: sound.name + ".caf", directory: SoundsDirectory.files, overwrite: true) else {
                return
            }
            let newSound = Sound(name: sound.name, url: fileUrl)
            do {
                let data = try JSONEncoder().encode(newSound)
                // Save encoded Sound data
                guard self.fileManager.save(file: data, named: sound.name, directory: SoundsDirectory.data, overwrite: true) != nil else {
                    return
                }
                self.delegate?.soundsManager(self, didDownload: newSound)
            } catch let err {
                self.delegate?.soundsManager(self, didEncounter: err)
            }
        }
        delegate?.soundsManager(self, didBeginDownloading: sound)
    }
    
}

extension SoundsManager {
    private(set)static var selectedSoundName: String {
        get {
            return UserDefaults.standard.string(forKey: "selectedSound") ?? "Bulletin"
        } set {
            UserDefaults.standard.set(newValue, forKey: "selectedSound")
        }
    }
    
    class func url(forSoundNamed name: String) -> URL? {
        FileManager.default.url(forFileNamed: name, directory: SoundsDirectory.files)
    }
    
    class func playbackUrl(forSoundNamed name: String) -> URL? {
        guard let url = url(forSoundNamed: name) else {
            return nil
        }
        // Files in Bundle will be here
        if url.isFileURL {
            return url
        }
        if url.isLocal {
            return SoundsDirectory.files.url.appendingPathComponent(url.path, isDirectory: false)
        }
        return url
    }
}

fileprivate extension PlistReader {
    class func dictionary(from file: String) -> [String: URL]? {
        if let path = Bundle.main.path(forResource: file, ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path) as? [String: String] {
            let keysValues: [(String, URL)] = dict.compactMap { key, value in
                guard let url = URL(string: value) else {
                    return nil
                }
                return (key, url)
            }
            return Dictionary(uniqueKeysWithValues: keysValues)
        } else {
            print("*** Couldn't create Dictionary from \(file).plist")
            return nil
        }
    }
}
