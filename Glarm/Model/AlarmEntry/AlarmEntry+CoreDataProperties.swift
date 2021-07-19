//
//  AlarmEntry+CoreDataProperties.swift
//  Glarm
//
//  Created by Adam Wienconek on 21/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//
//

import Foundation
import CoreData


extension AlarmEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AlarmEntry> {
        return NSFetchRequest<AlarmEntry>(entityName: "AlarmEntry")
    }

    @NSManaged private var latitude: Double
    @NSManaged private var longitude: Double
    @NSManaged private var name: String?
    @NSManaged private var radius: Double
    @NSManaged public var note: String
    @NSManaged private(set) var uuid: UUID
    @NSManaged public var soundName: String
    @NSManaged public var isMarked: Bool
    @NSManaged public var isSaved: Bool
    @NSManaged public var isRecurring: Bool
    @NSManaged public var dateCreated: Date
    @NSManaged public var category: Category?
    
    var uid: String {
        uuid.uuidString
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var locationInfo: LocationNotificationInfo? {
        get {
            guard let name = name else {
                return nil
            }
            return LocationNotificationInfo(name: name,
                                            coordinate: coordinate,
                                            radius: radius)
        } set {
            latitude = newValue?.coordinate.latitude ?? 0
            longitude = newValue?.coordinate.longitude ?? 0
            name = newValue?.name
            radius = newValue?.radius ?? 0
        }
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        guard value(forKey: "uuid") == nil else {
            return
        }
        dateCreated = Date()
        uuid = UUID()
    }
    
    public override func didChangeValue(forKey key: String) {
        super.didChangeValue(forKey: key)
        
        if key == "category",
           category != nil {
            isMarked = false
        }
    }

}

extension AlarmEntry : Identifiable {

}
