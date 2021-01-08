//
//  AudioBrowserController.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 11/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation
import AVFoundation

protocol AudioBrowserViewModelDelegate: class {
    func model(playerDidChangeStatus model: AudioBrowserViewModel, playing: Bool)
    func model(didReloadData model: AudioBrowserViewModel)
    func model(_ model: AudioBrowserViewModel, didChangeLoadingStatus loading: Bool, at indexPath: IndexPath)
    func model(_ model: AudioBrowserViewModel, didChangeButtonLoadingStatus loading: Bool)
}

class AudioBrowserViewModel: NSObject {
    private let player: AVPlayer
    
    private(set)var selectedSound: Sound {
        didSet {
            manager.setSound(selectedSound)
        }
    }
    
    weak var delegate: AudioBrowserViewModelDelegate?
    
    private let manager: SoundsManager
    
    private var downloadedSounds: [Sound]!
    private var availableSounds: [Sound]!
    private var timeControlObservation: NSKeyValueObservation!
    
    init(sound: Sound) {
        selectedSound = sound
        let item = AVPlayerItem(url: sound.playbackUrl)
        player = AVPlayer(playerItem: item)
        manager = SoundsManager()
        
        super.init()
        player.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        loadSounds()
    }
    
    func playbackButtonPressed() {
        if player.isPlaying {
            self.pause()
        } else {
            play()
        }
        delegate?.model(playerDidChangeStatus: self, playing: player.isPlaying)
    }
    
    private func loadSounds() {
        downloadedSounds = manager.downloadedSounds.sorted {
            $0.name < $1.name
        }
        availableSounds = manager.availableSounds.sorted {
            $0.name < $1.name
        }
    }
    
    private func loadSound(url: URL) {
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
    }
    
    func downloadSound(at path: IndexPath) {
        guard let sound = sound(at: path) else {
            return
        }
        manager.delegate = self
        manager.downloadSound(sound)
    }
    
    func play() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch let error {
            print(error.localizedDescription)
        }
        player.play()
        delegate?.model(playerDidChangeStatus: self, playing: true)
    }
    
    func pause() {
        player.pause()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch let error {
                print(error.localizedDescription)
            }
        }
        self.delegate?.model(playerDidChangeStatus: self, playing: false)
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "timeControlStatus", let change = change, let newValue = change[NSKeyValueChangeKey.newKey] as? Int, let oldValue = change[NSKeyValueChangeKey.oldKey] as? Int {
            let oldStatus = AVPlayer.TimeControlStatus(rawValue: oldValue)
            let newStatus = AVPlayer.TimeControlStatus(rawValue: newValue)
            if newStatus != oldStatus {
                DispatchQueue.main.async {
                    if newStatus == .playing || newStatus == .paused {
                        self.delegate?.model(self, didChangeButtonLoadingStatus: false)
                    } else {
                        self.delegate?.model(self, didChangeButtonLoadingStatus: true)
                    }
                }
            }
        }
    }
    
}

extension AudioBrowserViewModel {
    private func sound(at path: IndexPath) -> Sound? {
        switch Section(rawValue: path.section)! {
        case .sounds:
            return downloadedSounds.at(path.row)
        case .downloads:
            return availableSounds.at(path.row)
        }
    }
    
    var numberOfSections: Int {
        if manager.didDownloadAllSounds {
            return 1
        }
        return Section.count
    }
    
    func numberOfRows(in section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .sounds:
            return downloadedSounds.count
        case .downloads:
            return availableSounds.count
        }
    }
    
    func cellModel(at path: IndexPath) -> SoundCell.Model? {
        guard let sound = sound(at: path) else {
            return nil
        }
        return SoundCell.Model(sound: sound, isSelected: sound == selectedSound)
    }
    
    func headerModel(in section: Int) -> TableHeaderView.Model? {
        guard let sec = Section(rawValue: section) else {
                return nil
        }
        switch sec {
        case .sounds:
            return nil
        case .downloads:
            return .init(title: LocalizedStringKey.audio_moreSoundsHeader.localized,
                         buttonTitle: UnlockManager.unlocked ? nil : LocalizedStringKey.unlock.localized)
        }
    }
    
    func footer(in section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .sounds:
            return LocalizedStringKey.audio_toneBrowserFooter.localized
        case .downloads:
            return LocalizedStringKey.audio_downloadSoundsFooter.localized
        }
    }
    
    func didSelectRow(at path: IndexPath) {
        guard let sound = sound(at: path) else {
            return
        }
        defer {
            delegate?.model(playerDidChangeStatus: self, playing: player.isPlaying)
        }
        loadSound(url: sound.playbackUrl)
        if path.section == Section.sounds.rawValue {
            selectedSound = sound
            delegate?.model(didReloadData: self)
        }
        play()
    }
}

extension AudioBrowserViewModel: SoundsManagerDelegate {
    func soundsManager(_ manager: SoundsManager, didBeginDownloading sound: Sound) {
        
    }
    
    func soundsManager(_ manager: SoundsManager, didDownload sound: Sound) {
        loadSounds()
        delegate?.model(didReloadData: self)
    }
    
    func soundsManager(_ manager: SoundsManager, didEncounter error: Error) {
        DispatchQueue.main.async {
            //self.delegate
        }
    }
}

extension AudioBrowserViewModel {
    enum Section: Int, CaseIterable {
        case sounds
        case downloads
    }
}

fileprivate extension AVPlayer {
    var isPlaying: Bool {
        return rate > 0
    }
    
    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
}
