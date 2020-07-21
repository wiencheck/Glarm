//
//  ImageCacher.swift
//  Plum
//
//  Created by Adam Wienconek on 17/04/2020.
//  Copyright © 2020 adam.wienconek. All rights reserved.
//

import UIKit

final class ImageLoader {
    public static let shared = ImageLoader()
    
    private let cache: NSCache<NSString, UIImage>
    private let fileManager: FileManager
    
    private let rootDirectory: URL
    
    private init(limit: Int? = nil) {
        cache = NSCache()
        cache.countLimit = limit ?? 0
        fileManager = FileManager.default
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        rootDirectory = documentsDirectory.appendingPathComponent("images", isDirectory: true)
        //purgeImages(olderThan: 3)
    }
    
    @discardableResult
    func store(_ image: UIImage, named: String, overwrite: Bool = true) -> Bool {
        if !overwrite, cache.object(forKey: named as NSString) != nil {
            return false
        }
        cache.setObject(image, forKey: named as NSString)
        return true
    }
    
    @discardableResult
    func store(_ image: UIImage, named: String, to directory: Directory?, overwrite: Bool = true) -> Bool {
        store(image, named: named, overwrite: overwrite)
        return saveImage(image, named: named, to: directory?.path, overwrite: overwrite)
    }
    
    func retrieve(imageNamed name: String) -> UIImage? {
        return cache.object(forKey: name as NSString)
    }
    
    func retrieve(imageNamed name: String, from directory: Directory?) -> UIImage? {
        if let cached = retrieve(imageNamed: name) {
            return cached
        }
        return loadImageFromDisk(named: name, from: directory?.path)
    }
    
    func remove(imageNamed name: String) {
        cache.removeObject(forKey: name as NSString)
    }
    
    func remove(imageNamed name: String, from directory: Directory?) {
        remove(imageNamed: name)
        removeImageFromDisk(named: name, from: directory?.path)
    }
    
    func remove(folderNamed name: String) {
        removeFolderFromDisk(named: name)
    }
}

extension ImageLoader {
    @discardableResult
    private func saveImage(_ image: UIImage, named: String, to directory: String? = nil, overwrite: Bool) -> Bool {
        
        guard let dir = directoryUrl(named: directory) else {
            return false
        }
        guard let data = image.pngData() else {
            return false
        }
        
        let imagePath = dir.appendingPathComponent(named, isDirectory: false)

        if FileManager.default.fileExists(atPath: imagePath.path) {
            guard overwrite else {
                return false
            }
            do {
                try FileManager.default.removeItem(atPath: imagePath.path)
                print("Removed old image")
            } catch let removeError {
                print("couldn't remove file at path", removeError)
            }
        }
        
        do {
            try data.write(to: imagePath)
        } catch let error {
            print("error saving file with error", error)
            return false
        }
        return true
    }
    
    private func loadImageFromDisk(named: String, from directory: String?) -> UIImage? {
        
        guard let dir = directoryUrl(named: directory) else {
            return nil
        }
        let imagePath = dir.appendingPathComponent(named, isDirectory: false).path
        let image = UIImage(contentsOfFile: imagePath)
        return image
    }
    
    @discardableResult
    private func removeImageFromDisk(named: String, from directory: String?) -> Bool {
        guard let dir = directoryUrl(named: directory) else {
            return false
        }
        
        let imagePath = dir.appendingPathComponent(named, isDirectory: false)
        //Checks if file exists, removes it if so.
        if FileManager.default.fileExists(atPath: imagePath.path) {
            do {
                try FileManager.default.removeItem(atPath: imagePath.path)
                print("Removed old image")
            } catch let removeError {
                print("couldn't remove file at path", removeError)
                return false
            }
        }
        if let count = contentsCount(in: dir),
            count == 0 {
                do {
                    try FileManager.default.removeItem(at: dir)
                    print("Removed empty directory")
                } catch let removeError {
                    print("couldn't remove directory at path", removeError)
                    return false
                }
        }
        
        return true
    }
    
    @discardableResult
    private func removeFolderFromDisk(named: String) -> Bool {
        guard let dirPath = directoryUrl(named: named) else {
            return false
        }
        
        do {
            try FileManager.default.removeItem(at: dirPath)
            print("Removed directory")
        } catch let removeError {
            print("couldn't remove directory at path", removeError)
            return false
        }
        
        return true
    }
    
//    private func purgeImages(olderThan days: Int) {
//        guard let urls = fileManager.urls(for: directory) else {
//            return
//        }
//
//        for url in urls {
//            guard let date = fileModificationDate(at: url) else {
//                continue
//            }
//            if date.daysBetween(end: Date()) > days {
//                do {
//                    try fileManager.removeItem(at: url)
//                } catch let error {
//                    print("*** Couldn't remove at \(url.absoluteString) with error: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
    
//    private func fileModificationDate(at url: URL) -> Date? {
//        do {
//            let attr = try FileManager.default.attributesOfItem(atPath: url.path)
//            return attr[FileAttributeKey.modificationDate] as? Date
//        } catch {
//            return nil
//        }
//    }
    
    private func createRootDirectory() {
        if fileManager.fileExists(atPath: rootDirectory.path) {
            return
        }
        do {
            try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            print("Couldn't root directory, error: \(error.localizedDescription)")
        }
    }
    
    private func directoryUrl(named: String?) -> URL? {
        guard let named = named else {
            return rootDirectory
        }
        
        let path = rootDirectory.appendingPathComponent(named)
        
        if !fileManager.fileExists(atPath: path.path) {
            do {
                try fileManager.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                print("Couldn't create directory, error: \(error.localizedDescription)")
            }
        }
            
        return path
    }
    
    private func contentsCount(in directory: URL) -> Int? {
        guard let contents = try? fileManager.contentsOfDirectory(atPath: directory.path) else {
            return nil
        }
        return contents.count
    }
    
//    private func fileUrl(for name: String) -> URL? {
//        guard let documentsDirectory = FileManager.default.urls(for: directory, in: .userDomainMask).first else {
//            return nil
//        }
//
//        return documentsDirectory.appendingPathComponent(name)
//    }
}

extension ImageLoader {
    enum Directory {
        case artists
        case folders(String)
    }
}

extension ImageLoader.Directory {
    var path: String {
        switch self {
        case .artists:  return "artists"
        case .folders(let uid): return "folders/\(uid)"
        }
    }

    var absolutePath: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let p: String
        switch self {
        case .artists:  p = "artists"
        case .folders(let uid): p = "folders/\(uid)"
        }
        return documentsDirectory.appendingPathComponent(p)
    }
}

fileprivate extension FileManager {
    func urls(for directory: FileManager.SearchPathDirectory, skipsHiddenFiles: Bool = true) -> [URL]? {
        let documentsURL = urls(for: directory, in: .userDomainMask)[0]
        let fileURLs = try? contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [])
        return fileURLs
    }
}
