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
}

class AudioBrowserViewModel: NSObject {
    private var player: AVAudioPlayer? {
        didSet {
            oldValue?.stop()
            player?.delegate = self
        }
    }
    
    private let tones = AlarmTone.allCases
    var selectedTone: AlarmTone {
        didSet {
            AlarmTone.default = selectedTone
        }
    }
    
    weak var delegate: AudioBrowserViewModelDelegate?
    
    init(tone: AlarmTone) {
        selectedTone = tone
    }
    
    func playbackButtonPressed() {
        if let player = player {
            player.togglePlayback()
        } else if loadTone(selectedTone) {
            player?.play()
        }
        delegate?.model(playerDidChangeStatus: self, playing: player?.isPlaying ?? false)
    }
    
    private func loadTone(_ tone: AlarmTone) -> Bool {
        do {
            let url = URL(fileURLWithPath: Bundle.main.path(forResource: tone.rawValue, ofType: "caf")!)
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.caf.rawValue)
            return true
        } catch let error {
            print(error)
            return false
        }
    }
    
}

extension AudioBrowserViewModel {
    var numberOfSections: Int {
        return 1
    }
    
    var numberOfRows: Int {
        return tones.count
    }
    
    func cellDetails(at path: IndexPath) -> (String, Bool) {
        let tone = tones[path.row]
        return (tone.rawValue, tone == selectedTone)
    }
    
    func didSelectRow(at path: IndexPath) {
        let tone = tones[path.row]
        defer {
            delegate?.model(playerDidChangeStatus: self, playing: player?.isPlaying ?? false)
            delegate?.model(didReloadData: self)
        }
        guard loadTone(tone) else {
            return
        }
        player!.play()
        
        selectedTone = tone
    }
}

extension AudioBrowserViewModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        delegate?.model(playerDidChangeStatus: self, playing: player.isPlaying)
    }
}

fileprivate extension AVAudioPlayer {
    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
}
