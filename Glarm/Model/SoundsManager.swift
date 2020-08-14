//
//  SoundsManager.swift
//  Glarm
//
//  Created by Adam Wienconek on 17/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation
import UserNotifications
import Alamofire
import AVFoundation

protocol SoundsManagerDelegate: class {
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
    
    func setSound(_ sound: Sound) {
        SoundsManager.selectedSound = sound
    }
    
    //    func removeSound(_ sound: Sound) {
    //
    //    }
    
    func downloadSound(_ sound: Sound) {
        AF.download(sound.url).responseData { response in
            if let error = response.error {
                self.delegate?.soundsManager(self, didEncounter: error)
                return
            }
            guard let data = response.value,
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
    private(set)static var selectedSound: Sound {
        get {
            guard let data = UserDefaults.standard.data(forKey: "selectedSound"),
                let sound = try? JSONDecoder().decode(Sound.self, from: data) else {
                    return .default
            }
            return sound
        } set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                return
            }
            UserDefaults.standard.set(data, forKey: "selectedSound")
        }
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
