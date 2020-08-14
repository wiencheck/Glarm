//
//  FileManager.swift
//  Glarm
//
//  Created by Adam Wienconek on 17/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation

protocol Directory {
    var rawValue: String { get }
    var searchPath: FileManager.SearchPathDirectory { get }
}

extension Directory {
    var searchPath: FileManager.SearchPathDirectory {
        return .documentDirectory
    }

    var url: URL {
        return FileManager.default.directoryUrl(named: rawValue, searchPath: searchPath, parentDirectory: nil, shouldCreateNewDirectory: false)!
    }
}

extension FileManager {
    func url(for searchPath: SearchPathDirectory) -> URL {
        return urls(for: searchPath, in: .userDomainMask).first!
    }
    
    func directoryUrl(named name: String, searchPath: SearchPathDirectory = .documentDirectory, parentDirectory: String? = nil, shouldCreateNewDirectory: Bool = true) -> URL? {
        
        var subPath = ""
        if let parent = parentDirectory {
            // Append with parent directory.
            subPath += parent + "/"
        }
        // Append with new directory.
        subPath += name + "/"

        let fullPath = searchPath.url.appendingPathComponent(subPath)
        if !fileExists(atPath: fullPath.path), shouldCreateNewDirectory {
            do {
                try createDirectory(at: fullPath, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                print("Couldn't create directory, error: \(error.localizedDescription)")
                return nil
            }
        }
        return fullPath
    }
    
    func directoryUrl(directory: Directory, shouldCreateNewDirectory: Bool = true) -> URL? {
        return directoryUrl(named: directory.rawValue, searchPath: directory.searchPath, parentDirectory: nil, shouldCreateNewDirectory: shouldCreateNewDirectory)
    }
    @discardableResult
    func remove(folderNamed name: String, searchPath: SearchPathDirectory = .documentDirectory, parentDirectory: String?) -> Bool {
        guard let dirPath = directoryUrl(named: name, searchPath: searchPath, parentDirectory: parentDirectory) else {
            return false
        }
        
        do {
            try removeItem(at: dirPath)
        } catch let removeError {
            print("couldn't remove directory at path", removeError)
            return false
        }
        return true
    }
    
    @discardableResult
    func remove(directory: Directory) -> Bool {
        return remove(folderNamed: directory.rawValue, searchPath: directory.searchPath, parentDirectory: nil)
    }
    
    /// Returns name of the file without leading path.
    @discardableResult
    func save(file: Data, named name: String, searchPath: SearchPathDirectory = .documentDirectory, directory: String? = nil, overwrite: Bool) -> URL? {
        
        var fullPath: URL
        if let directory = directory, let dirUrl = directoryUrl(named: directory, searchPath: searchPath, shouldCreateNewDirectory: true) {
            fullPath = dirUrl
        } else {
            fullPath = searchPath.url
        }
        fullPath = fullPath.appendingPathComponent(name.replacingOccurrences(of: " ", with: ""), isDirectory: false)
        if fileExists(atPath: fullPath.path) {
            guard overwrite else {
                return URL(string: fullPath.lastPathComponent)
            }
            do {
                try removeItem(atPath: fullPath.path)
            } catch let removeError {
                print("couldn't remove file at path", removeError)
            }
        }
        
        do {
            try file.write(to: fullPath)
        } catch let error {
            print("error saving file with error", error)
            return nil
        }
        return URL(string: fullPath.lastPathComponent)
    }
    
    @discardableResult
    func save(file: Data, named name: String, directory: Directory, overwrite: Bool) -> URL? {
        return save(file: file, named: name, searchPath: directory.searchPath, directory: directory.rawValue, overwrite: overwrite)
    }
    
    func load(fileNamed name: String, searchPath: SearchPathDirectory = .documentDirectory, directory: String?) -> Data? {
        
        var fullPath: URL
        if let directory = directory, let dirUrl = directoryUrl(named: directory, searchPath: searchPath, shouldCreateNewDirectory: false) {
            fullPath = dirUrl
        } else {
            fullPath = searchPath.url
        }
        fullPath = fullPath.appendingPathComponent(name, isDirectory: false)
        
        return try? Data(contentsOf: fullPath)
    }
    
    func load(fileNamed name: String, directory: Directory) -> Data? {
        return load(fileNamed: name, searchPath: directory.searchPath, directory: directory.rawValue)
    }
    
    @discardableResult
    func remove(fileNamed name: String, searchPath: SearchPathDirectory = .documentDirectory, from directory: String?, shouldRemoveEmptyDirectory: Bool = true) -> Bool {
        
        var fullPath: URL
        if let directory = directory, let dirUrl = directoryUrl(named: directory, searchPath: searchPath, shouldCreateNewDirectory: false) {
            fullPath = dirUrl
        } else {
            fullPath = searchPath.url
        }
        fullPath = fullPath.appendingPathComponent(name, isDirectory: false)
        
        //Checks if file exists, removes it if so.
        if fileExists(atPath: fullPath.path) {
            do {
                try removeItem(atPath: fullPath.path)
            } catch let removeError {
                print("couldn't remove file at path", removeError)
                return false
            }
        }
        
        let directoryPath = fullPath.deletingLastPathComponent()
        if shouldRemoveEmptyDirectory, let count = contentsCount(in: directoryPath.path),
            count == 0 {
                do {
                    try removeItem(at: directoryPath)
                    print("Removed empty directory")
                } catch let removeError {
                    print("couldn't remove directory at path", removeError)
                    return false
                }
        }
        return true
    }
    
    func contentsCount(searchPath: SearchPathDirectory = .documentDirectory, in directory: String) -> Int? {
        guard let contents = try? contentsOfDirectory(atPath: searchPath.url.appendingPathComponent(directory, isDirectory: false).path) else {
            return nil
        }
        return contents.count
    }
    
    func contentsCount(directory: Directory) -> Int? {
        return contentsCount(searchPath: directory.searchPath, in: directory.rawValue)
    }
    
    func contents(searchPath: SearchPathDirectory = .documentDirectory, of directory: String) -> [Data]? {
        let fullPath = searchPath.url.appendingPathComponent(directory)
        guard let _contents = try? contentsOfDirectory(atPath: fullPath.path) else {
            return nil
        }
        return _contents.compactMap { fileName in
            contents(atPath: fullPath.appendingPathComponent(fileName, isDirectory: false).path)
        }
    }
    
    func contents(directory: Directory) -> [Data]? {
        return contents(searchPath: directory.searchPath, of: directory.rawValue)
    }
}

fileprivate extension FileManager.SearchPathDirectory {
    var url: URL {
        return FileManager.default.urls(for: self, in: .userDomainMask).first!
    }
}

