//
//  PhotoModelFileManager.swift
//  VibeSync
//
//  Created by Ayyoub on 9/3/2026.
//

import Foundation
import SwiftUI

class ImageFileCacheService {
    static let shared = ImageFileCacheService()

    private let folderName = "downloaded_photos"
    private let maxCacheSizeBytes: Int = 100 * 1024 * 1024  // 100MB
    private let maxAgeSeconds: TimeInterval = 60 * 60 * 24 * 7  // 7 days

    private init() {
        createFolderIfNeeded()

        Task.detached(priority: .background) {
            await self.cleanup()
        }
    }

    private func createFolderIfNeeded() {
        guard let url = getFolderPath() else { return }

        if !FileManager.default.fileExists(atPath: url.path()) {
            do {
                try FileManager.default.createDirectory(
                    at: url,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                print("Created Photo Cache Folder!")
            } catch let error {
                print("Error creating photo cache folder: \(error)")
            }
        }
    }

    private func getImagePath(key: String) -> URL? {
        guard let folder = getFolderPath() else {
            return nil
        }

        return folder.appendingPathComponent(key + ".jpg")
    }

    private func getFolderPath() -> URL? {
        return FileManager
            .default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(folderName)
    }

    // MARK: - Public API

    func add(key: String, value: UIImage) {
        guard let data = value.jpegData(compressionQuality: 1),
            let url = getImagePath(key: key)
        else { return }

        do {
            try data.write(to: url)
            evictIfNeeded()
        } catch let error {
            print("Error saving photo to file manager. \(error)")
        }
    }

    func get(key: String) -> UIImage? {
        guard let url = getImagePath(key: key),
            FileManager.default.fileExists(atPath: url.path())
        else {
            return nil
        }

        // Update access date for LRU tracking (Least Recently Used) - for eviction
        try? FileManager.default.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: url.path()
        )

        return UIImage(contentsOfFile: url.path)
    }

    func remove(key: String) {
        guard let url = getImagePath(key: key) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    func clearAll() {
        guard let folder = getFolderPath() else { return }
        try? FileManager.default.removeItem(at: folder)
        createFolderIfNeeded()
    }

    // MARK: - Eviction

    // Removes files over maxAgeSeconds, then if still over size limit
    // evicts least recently used until under limit
    private func evictIfNeeded() {
        guard let folder = getFolderPath() else { return }

        let fm = FileManager.default
        guard
            let files = try? fm.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [
                    .fileSizeKey, .contentModificationDateKey,
                ],
                options: .skipsHiddenFiles
            )
        else { return }

        let now = Date()

        // 1. Evict expired files first
        for file in files {
            guard
                let attrs = try? file.resourceValues(forKeys: [
                    .contentModificationDateKey
                ]),
                let modified = attrs.contentModificationDate
            else { continue }

            if now.timeIntervalSince(modified) > maxAgeSeconds {
                try? fm.removeItem(at: file)
            }
        }

        // 2. If still over size limit, evict LRU until under limit
        evictLRUIfOverLimit()
    }

    private func evictLRUIfOverLimit() {
        guard let folder = getFolderPath() else { return }
        let fm = FileManager.default

        guard
            let files = try? fm.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [
                    .fileSizeKey, .contentModificationDateKey,
                ],
                options: .skipsHiddenFiles
            )
        else { return }

        // Build list of (url, size, lastAccessed)
        var fileInfos: [(url: URL, size: Int, date: Date)] = files.compactMap {
            url in
            guard
                let attrs = try? url.resourceValues(
                    forKeys: [.fileSizeKey, .contentModificationDateKey]
                )
            else { return nil }
            return (
                url: url,
                size: attrs.fileSize ?? 0,
                date: attrs.contentModificationDate ?? .distantPast
            )
        }

        let totalSize = fileInfos.reduce(0) { $0 + $1.size }
        guard totalSize > maxCacheSizeBytes else { return }

        // Sort by oldest access first (LRU)
        fileInfos.sort { $0.date < $1.date }

        var currentSize = totalSize
        for file in fileInfos {
            guard currentSize > maxCacheSizeBytes else { break }
            try? fm.removeItem(at: file.url)
            currentSize -= file.size
            print(
                "Evicted (LRU): \(file.url.lastPathComponent), freed \(file.size / 1024)KB"
            )
        }
    }

    // MARK: - Cleanup (called on init in background)

    func cleanup() {
        evictIfNeeded()
        print("Cache size after cleanup: \(currentCacheSizeFormatted())")
    }

    // MARK: - Diagnostics

    func currentCacheSizeBytes() -> Int {
        guard let folder = getFolderPath(),
            let files = try? FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.fileSizeKey],
                options: .skipsHiddenFiles
            )
        else { return 0 }

        return files.reduce(0) { total, url in
            let size =
                (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + size
        }
    }

    func currentCacheSizeFormatted() -> String {
        let bytes = currentCacheSizeBytes()
        let mb = Double(bytes) / (1024 * 1024)
        return String(format: "%.2f MB", mb)
    }

}
