//
//  main.swift
//  PhotosSortBySize
//
//  Created by Damian Stewart on 12.09.21.
//

import Foundation

import Photos

extension PHAsset {
    var fileSize: Int? {
        get {
            let resource = PHAssetResource.assetResources(for: self)
            return resource.first?.value(forKey: "fileSize") as? Int
        }
    }
}

extension PHAssetMediaType {
    var name: String {
        switch self {
        case PHAssetMediaType.image:
            return "image"
        case PHAssetMediaType.audio:
            return "audio"
        case PHAssetMediaType.video:
            return "video"
        case PHAssetMediaType.unknown:
            return "unknown"
        @unknown default:
            return "missing"
        }
    }
}


let mainGroup = DispatchGroup()
mainGroup.enter()

PHPhotoLibrary.requestAuthorization(for: .readWrite) { (status) in
    go()
    mainGroup.leave()
}

mainGroup.wait()

struct Info {
    let type: PHAssetMediaType
    let date: Date?
    let size: Int
    init(from asset: PHAsset) {
        self.type = asset.mediaType
        self.date = asset.creationDate
        self.size = asset.fileSize ?? -1
    }
    
    var sizeMb: String {
        let mb = Double(self.size) / (1024*1024)
        if mb > 10 {
            return "\(Int(mb))"
        } else if mb > 0.1 {
            let fracPart = mb - floor(mb)
            return "\(Int(mb)).\(Int(fracPart*10))"
        } else {
            return "<0.1"
        }
    }

    func print() {
        Swift.print("\(type.name) @ \(date ?? Date.init(timeIntervalSince1970: 0)), \(sizeMb)mb")

    }
}

func go() {

    let allPhotosOptions = PHFetchOptions()
    allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
    let fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
    
    var infos = [Info]()
    print("collecting sizes on \(fetchResult.count) assets...")
    for i in 0..<fetchResult.count {
        let asset = fetchResult.object(at: i)
        infos.append(Info(from: asset))
        if (i%1000 == 0) {
            print("\(i)...")
        }
    }
    print("\(fetchResult.count)...")
    print("... done")

    let totalSizeBytes = infos.reduce(0, { $0 + $1.size })
    print("total size: \(ceil(Double(totalSizeBytes) / (1024*1024))) mb")
    infos.sort { $0.size > $1.size }
    
    for i in 0..<infos.count {
        infos[i].print()
    }
    
}
 
