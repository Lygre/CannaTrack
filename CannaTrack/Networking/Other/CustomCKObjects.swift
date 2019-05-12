//
//  CustomCKObjects.swift
//  CannaTrack
//
//  Created by Hugh Broome on 4/19/19.
//  Copyright © 2019 Lygre. All rights reserved.
//
//
//  CloudKitNote.swift
//  Note
//
//  Created by Paul Young.
//

import CloudKit

enum CloudKitCannabisProductError : Error {
	case productNotFound
	case newerVersionAvailable
	case unexpected
}

public protocol CloudKitCannabisProductDelegate {
	func cloudKitCannabisProductChanged(note: CloudKitCannabisProduct)
}

public class CloudKitCannabisProduct : CloudKitCannabisDatabaseDelegate {

	public var delegate: CloudKitCannabisProductDelegate?
	private(set) var text: String?
	private(set) var modified: Date?
//	text, and version are our defined fields

	private let recordName = "Product"
	private let version = 1
	private var noteRecord: CKRecord?

	public init() {
		CloudKitCannabisDatabase.shared.delegate = self
	}

	// Map from CKRecord to our native data fields
	private func syncToRecord(record: CKRecord) -> (String?, Date?, Error?) {
		let version = record["version"] as? NSNumber
		guard version != nil else {
			return (nil, nil, CloudKitCannabisProductError.unexpected)
		}
		guard version!.intValue <= self.version else {
			// Simple example of a version check, in case the user has
			// has updated the client on another device but not this one.
			// A possible response might be to prompt the user to see
			// if the update is available on this device as well.
			return (nil, nil, CloudKitCannabisProductError.newerVersionAvailable)
		}
		let textAsset = record["text"] as? CKAsset
		guard textAsset != nil else {
			return (nil, nil, CloudKitCannabisProductError.productNotFound)
		}

		// CKAsset data is stored as a local temporary file. Read it
		// into a String here.
		let modified = record["modified"] as? Date
		do {

			//unwrapping might be bad here!!!!!!!
			let text = try String(contentsOf: textAsset!.fileURL!)
			return (text, modified, nil)
		}
		catch {
			return (nil, nil, error)
		}
	}

	// Load a Note from iCloud
	public func load(completion: @escaping (String?, Date?, Error?) -> Void) {
		let cannabisDB = CloudKitCannabisDatabase.shared
		cannabisDB.loadRecord(name: recordName) { (record, error) in
			guard error == nil else {
				guard let ckerror = error as? CKError else {
					completion(nil, nil, error)
					return
				}
				if ckerror.isRecordNotFound() {
					// This typically means we just haven’t saved it yet,
					// for example the first time the user runs the app.
					completion(nil, nil, CloudKitCannabisProductError.productNotFound)
					return
				}
				completion(nil, nil, error)
				return
			}
			guard let record = record else {
				completion(nil, nil, CloudKitCannabisProductError.unexpected)
				return
			}

			let (text, modified, error) = self.syncToRecord(record: record)
			self.noteRecord = record
			self.text = text
			self.modified = modified
			completion(text, modified, error)
		}
	}

	// Save a Note to iCloud. If necessary, handle the case of a conflicting change.
	public func save(text: String, modified: Date, completion: @escaping (Error?) -> Void) {
		guard let record = self.noteRecord else {
			// We don’t already have a record. See if there’s one up on iCloud
			let cannabisDB = CloudKitCannabisDatabase.shared
			cannabisDB.loadRecord(name: recordName) { record, error in
				if let error = error {
					guard let ckerror = error as? CKError else {
						completion(error)
						return
					}
					guard ckerror.isRecordNotFound() else {
						completion(error)
						return
					}
					// No record up on iCloud, so we’ll start with a
					// brand new record.
					let recordID = CKRecord.ID(recordName: self.recordName, zoneID: cannabisDB.zoneID!)
					self.noteRecord = CKRecord(recordType: "note", recordID: recordID)
					self.noteRecord?["version"] = NSNumber(value:self.version)
				}
				else {
					guard record != nil else {
						completion(CloudKitCannabisProductError.unexpected)
						return
					}
					self.noteRecord = record
				}
				// Repeat the save attempt now that we’ve either fetched
				// the record from iCloud or created a new one.
				self.save(text: text, modified: modified, completion: completion)
			}
			return
		}

		// Save the note text as a temp file to use as the CKAsset data.
		let tempDirectory = NSTemporaryDirectory()
		let tempFileName = NSUUID().uuidString
		let tempFileURL = NSURL.fileURL(withPathComponents: [tempDirectory, tempFileName])
		do {
			try text.write(to: tempFileURL!, atomically: true, encoding: .utf8)
		}
		catch {
			completion(error)
			return
		}
		let textAsset = CKAsset(fileURL: tempFileURL!)
		record["text"] = textAsset
		record["modified"] = modified as NSDate
		saveRecord(record: record) { updated, error in
			defer {
				try? FileManager.default.removeItem(at: tempFileURL!)
			}
			guard error == nil else {
				completion(error)
				return
			}
			guard !updated else {
				// During the save we found another version on the server side and
				// the merging logic determined we should update our local data to match
				// what was in the iCloud database.
				let (text, modified, syncError) = self.syncToRecord(record: self.noteRecord!)
				guard syncError == nil else {
					completion(syncError)
					return
				}

				self.text = text
				self.modified = modified

				// Let the UI know the Note has been updated.
				self.delegate?.cloudKitCannabisProductChanged(note: self)
				completion(nil)
				return
			}

			self.text = text
			self.modified = modified
			completion(nil)
		}
	}

	// This internal saveRecord method will be called repeatedly if needed in the case
	// of a merge. In those cases we don’t have to repeat the CKRecord setup.
	private func saveRecord(record: CKRecord, completion: @escaping (Bool, Error?) -> Void) {
		let noteDB = CloudKitCannabisDatabase.shared
		noteDB.saveRecord(record: record) { error in
			guard error == nil else {
				guard let ckerror = error as? CKError else {
					completion(false, error)
					return
				}
				let (clientRec, serverRec) = ckerror.getMergeRecords()
				guard let clientRecord = clientRec, let serverRecord = serverRec else {
					completion(false, error)
					return
				}

				// This is the merge case. Check the modified dates and choose
				// the most-recently modified one as the winner. This is just a very
				// basic example of conflict handling, more sophisticated data models
				// will likely require more nuance here.
				let clientModified = clientRecord["modified"] as? Date
				let serverModified = serverRecord["modified"] as? Date
				if (clientModified?.compare(serverModified!) == .orderedDescending) {
					// We’ve decided ours is the winner, so do the update again
					// using the current iCloud ServerRecord as the base CKRecord.
					serverRecord["text"] = clientRecord["text"]
					serverRecord["modified"] = clientModified! as NSDate
					self.saveRecord(record: serverRecord) { modified, error in
						self.noteRecord = serverRecord
						completion(true, error)
					}
				}
				else {
					// We’ve decided the iCloud version is the winner.
					// No need to overwrite it there but we’ll update our
					// local information to match to stay in sync.
					self.noteRecord = serverRecord
					completion(true, nil)
				}
				return
			}
			completion(false, nil)
		}
	}

	// CloudKitNoteDatabaseDelegate call:
	public func cloudKitCannabisProductRecordChanged(record: CKRecord) {
		if record.recordID == self.noteRecord?.recordID {
			let (text, modified, error) = self.syncToRecord(record: record)
			guard error == nil else {
				return
			}

			self.noteRecord = record
			self.text = text
			self.modified = modified
			self.delegate?.cloudKitCannabisProductChanged(note: self)
		}
	}
}