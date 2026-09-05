//
//  Jobs.swift
//  lastminute
//
//  Created by Jabran Ali on 22/06/2025.

import SwiftUI
import FirebaseFirestore
import Combine
import FirebaseAuth
import CoreLocation

// MARK: - Candidate Struct
struct Candidate: Codable, Identifiable, Equatable {
    var id: String           // unique candidate ID (e.g., user id)
    var name: String
    var surname: String
    var experience: String
    var age: Int
    var number: String       // phone number property
    var skills: [String]          // NEW
    var hasDrivingLicense: Bool 

    static func == (lhs: Candidate, rhs: Candidate) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Candidate {
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "surname": surname,
            "experience": experience,
            "age": age,
            "number": number,
            "skills": skills,                // NEW
            "hasDrivingLicense": hasDrivingLicense // NEW
        ]
    }
}

// MARK: - Job Struct
struct Job: Identifiable, Equatable {
    var id: String             // Firestore document ID
    var title: String
    var location: String
    var pay: String
    var date: Date
    var time: String
    var postedBy: String
    var status: String
    var candidates: [Candidate]? // List of candidates who applied
    var completionCode: String?
    var acceptedCandidate: Candidate?
    var geoLocation: GeoPoint
    var requiredSkills: [String] = []        // NEW
    var requiresDrivingLicense: Bool = false // NEW
    var acceptedWorkerId: String? = nil
    var expiryDate: Date? = nil
    var createdAt: Date? = nil
    
    var timeUntilExpiry: TimeInterval? {
            guard let expiryDate = expiryDate else { return nil }
            return expiryDate.timeIntervalSinceNow
        }

        var isExpired: Bool {
            guard let expiryDate = expiryDate else { return false }
            return Date() > expiryDate
        }
    
    static func == (lhs: Job, rhs: Job) -> Bool {
        return lhs.id == rhs.id &&
            lhs.status == rhs.status &&
            lhs.candidates == rhs.candidates &&
            lhs.acceptedCandidate == rhs.acceptedCandidate &&
            lhs.completionCode == rhs.completionCode
    }
    
    // Updated memberwise initializer including completionCode
    init(
        id: String,
        title: String,
        location: String,
        pay: String,
        date: Date,
        time: String,
        postedBy: String,
        status: String,
    geoLocation: GeoPoint,
        candidates: [Candidate]? = nil,
        acceptedCandidate: Candidate? = nil,
        completionCode: String? = nil,
        requiredSkills: [String] = [],          // NEW
            requiresDrivingLicense: Bool = false    //
    ) {
        self.id = id
        self.title = title
        self.location = location
        self.pay = pay
        self.date = date
        self.time = time
        self.postedBy = postedBy
        self.status = status
        self.candidates = candidates
        self.acceptedCandidate = acceptedCandidate
        self.completionCode = completionCode
        self.geoLocation = geoLocation
    }
    
    // Convert to dictionary for Firestore including completionCode
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "title": title,
            "location": location,
            "pay": pay,
            "date": Timestamp(date: date),
            "time": time,
            "postedBy": postedBy,
            "status": status,
            "requiredSkills": requiredSkills,                   // NEW
            "requiresDrivingLicense": requiresDrivingLicense,
            "geoLocation": geoLocation
        ]
        
        if let candidates = candidates {
            dict["candidates"] = candidates.map { $0.toDictionary() }
        }
        
        if let accepted = acceptedCandidate {
            dict["acceptedCandidate"] = accepted.toDictionary()
        }
        
        if let code = completionCode {
            dict["completionCode"] = code
        }
        
        if let expiryDate = expiryDate {
                dict["expiryDate"] = Timestamp(date: expiryDate)
            }

        if let createdAt = createdAt {
                dict["createdAt"] = Timestamp(date: createdAt)
            }
        
        return dict
    }
    
    // Initialize from Firestore document data
    init?(id: String, data: [String: Any]) {
        self.id = id
        guard
            let title = data["title"] as? String,
            let location = data["location"] as? String,
            let pay = data["pay"] as? String,
            let timestamp = data["date"] as? Timestamp,
            let time = data["time"] as? String,
            let postedBy = data["postedBy"] as? String,
            let status = data["status"] as? String
                
        else {
            return nil
        }
        
        self.title = title
        self.location = location
        self.pay = pay
        self.date = timestamp.dateValue()
        self.time = time
        self.postedBy = postedBy
        self.status = status
        self.geoLocation = data["geoLocation"] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0)
        self.completionCode = data["completionCode"] as? String
        
        if let expiryTimestamp = data["expiryDate"] as? Timestamp {
                self.expiryDate = expiryTimestamp.dateValue()
            }

        if let createdTimestamp = data["createdAt"] as? Timestamp {
                self.createdAt = createdTimestamp.dateValue()
            }
        
        if let candidatesData = data["candidates"] as? [[String: Any]] {
            self.candidates = candidatesData.compactMap { dict -> Candidate? in
                guard
                    let id = dict["id"] as? String,
                    let name = dict["name"] as? String,
                    let surname = dict["surname"] as? String,
                    let experience = dict["experience"] as? String,
                    let age = dict["age"] as? Int,
                    let number = dict["number"] as? String
                        
                else { return nil }
                
                let skills = dict["skills"] as? [String] ?? []
                        let hasDrivingLicense = dict["hasDrivingLicense"] as? Bool ?? false
                return Candidate(
                           id: id,
                           name: name,
                           surname: surname,
                           experience: experience,
                           age: age,
                           number: number,
                           skills: skills,
                           hasDrivingLicense: hasDrivingLicense
                       )
            }
        } else {
            self.candidates = nil
        }
        
        if let acceptedData = data["acceptedCandidate"] as? [String: Any],
           let id = acceptedData["id"] as? String,
           let name = acceptedData["name"] as? String,
           let surname = acceptedData["surname"] as? String,
           let experience = acceptedData["experience"] as? String,
           let age = acceptedData["age"] as? Int,
           let number = acceptedData["number"] as? String
        {
            // Read new fields from Firestore, default if missing
            let skills = acceptedData["skills"] as? [String] ?? []
            let hasDrivingLicense = acceptedData["hasDrivingLicense"] as? Bool ?? false

            self.acceptedCandidate = Candidate(
                id: id,
                name: name,
                surname: surname,
                experience: experience,
                age: age,
                number: number,
                skills: skills,
                hasDrivingLicense: hasDrivingLicense
            )
        } else {
            self.acceptedCandidate = nil
        }

    }
}


// MARK: - JobStore Class



class JobStore: ObservableObject {
    @Published var activeJobs: [Job] = []          // All relevant active jobs (merged)
    @Published var workerActiveJobs: [Job] = []    // Jobs accepted by worker user, status accepted
    
    @Published var completedJobs: [Job] = []
    @Published var businessadvertisedJobs: [Job] = []
    @Published var businessAcceptedJobs: [Job] = []
    @Published var deletedJobs: [Job] = []
    @Published var eligibleJobs: [Job] = []
    @Published var currentCandidate: Candidate?
    
    
    private var db = Firestore.firestore()
    
    // Store listener registrations for later removal
    private var activeJobsListener: ListenerRegistration?
    private var completedJobsListener: ListenerRegistration?
    private var advertisedJobsListener: ListenerRegistration?
    private let locationManager = CLLocationManager()
    // Computed property to get current user ID
    private var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    // Start all listeners for a user (removes existing listeners first)
    func startListeners(for userId: String, userRole: String) {
        print("🔁 Starting all listeners for user: \(userId) with role: \(userRole)")
        
        stopListeners()
        
        listenForActiveJobs(userId: userId, userRole: userRole)
        listenForCompletedJobs(userId: userId, userRole: userRole)
        listenForAdvertisedJobs(userId: userId, userRole: userRole)

        // Always load the real worker profile so applications use correct data
        if userRole == "worker" {
            fetchCurrentCandidate(userId: userId)
        }
    }
    
    // Manually refresh all listeners (used for pull-to-refresh)
    func refresh() async {
        guard let uid = currentUserID else { return }
        let role = await fetchUserRoleString(uid: uid)
        await MainActor.run {
            self.startListeners(for: uid, userRole: role)
        }
        // Give the snapshot listeners a moment to deliver fresh data
        try? await Task.sleep(nanoseconds: 700_000_000)
    }

    private func fetchUserRoleString(uid: String) async -> String {
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            return (snapshot.data()?["role"] as? String) ?? "worker"
        } catch {
            return "worker"
        }
    }

    // Stop all listeners to prevent duplicates and memory leaks
    func stopListeners() {
        activeJobsListener?.remove()
        activeJobsListener = nil
        
        completedJobsListener?.remove()
        completedJobsListener = nil
        
        advertisedJobsListener?.remove()
        advertisedJobsListener = nil
    }
    
    deinit {
        // Clean up listeners when JobStore is deallocated
        stopListeners()
    }
    
    // Listen for advertised jobs with status "open"
    func listenForAdvertisedJobs(userId: String, userRole: String) {
        advertisedJobsListener?.remove()
        
        var query: Query = db.collection("jobs")
            .whereField("status", isEqualTo: "open")
        
        if userRole == "business" {
            // Business sees only their own advertised jobs
            query = query.whereField("postedBy", isEqualTo: userId)
        }
        // Workers see all open jobs, no additional filter
        
        advertisedJobsListener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching advertised jobs: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            let jobs = documents.compactMap { doc -> Job? in
                let job = Job(id: doc.documentID, data: doc.data())
                if job == nil {
                    print("⚠️ Failed to decode advertised job from doc: \(doc.documentID)")
                }
                return job
            }
            // Sort latest posted first
            .sorted { self.jobSortKey($0) > self.jobSortKey($1) }
            
            DispatchQueue.main.async {
                self.businessadvertisedJobs = jobs
                print("Fetched \(jobs.count) advertised jobs")
            }
        }
    }
    
    
    // Listen for active jobs related to the user (either posted by or accepted by them)
    private var businessJobsListener: ListenerRegistration?
    private var workerJobsListener: ListenerRegistration?
    
    func listenForActiveJobs(userId: String, userRole: String) {
        print("👤 Listening for active jobs for user: \(userId)")
        
        businessJobsListener?.remove()
        workerJobsListener?.remove()
        
        // Only business users track their own posted jobs here.
        // For workers, listenForAdvertisedJobs is the sole (sorted) writer of businessadvertisedJobs.
        if userRole == "business" {
            businessJobsListener = db.collection("jobs")
                .whereField("postedBy", isEqualTo: userId)
                .whereField("status", in: ["open", "accepted"])
                .addSnapshotListener { snapshot, error in
                    guard let documents = snapshot?.documents else { return }
                    let businessJobs = documents.compactMap { Job(id: $0.documentID, data: $0.data()) }
                    
                    DispatchQueue.main.async {
                        let now = Date()
                        
                        // Sorted latest posted first
                        self.businessadvertisedJobs = businessJobs
                            .filter { $0.status == "open" && ($0.expiryDate ?? Date.distantFuture) > now }
                            .sorted { self.jobSortKey($0) > self.jobSortKey($1) }
                        self.businessAcceptedJobs   = businessJobs
                            .filter { $0.status == "accepted" && ($0.expiryDate ?? Date.distantFuture) > now }
                            .sorted { self.jobSortKey($0) > self.jobSortKey($1) }
                        self.activeJobs = self.businessAcceptedJobs + self.workerActiveJobs
                        
                        print("✅ Fetched \(self.businessadvertisedJobs.count) advertised jobs")
                        print("✅ Fetched \(self.businessAcceptedJobs.count) accepted jobs")
                    }
                }
        }
        
        
        workerJobsListener = db.collection("jobs")
            .whereField("acceptedWorkerId", isEqualTo: userId)
            .whereField("status", isEqualTo: "accepted")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let now = Date() // <-- Define 'now' here, inside the closure
                let workerJobs = documents.compactMap { Job(id: $0.documentID, data: $0.data()) }
                    .filter { ($0.expiryDate ?? Date.distantFuture) > now }
                DispatchQueue.main.async {
                    self.workerActiveJobs = workerJobs
                    // Merge only accepted business jobs + worker accepted jobs
                    self.activeJobs = self.businessAcceptedJobs + workerJobs
                    print("✅ Synced Worker Jobs: \(workerJobs.count)")
                }
            }
    }
    // Listen for completed jobs with status "completed"
    
    func listenForCompletedJobs(userId: String, userRole: String) {
        completedJobsListener?.remove()
        
        var query: Query = db.collection("jobs")
            .whereField("status", isEqualTo: "completed")
        
        // Apply role-based filtering
        if userRole == "business" {
            query = query.whereField("postedBy", isEqualTo: userId)
        } else if userRole == "worker" {
            query = query.whereField("acceptedWorkerId", isEqualTo: userId)
        }
        
        completedJobsListener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching completed jobs: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            let jobs = documents.compactMap { doc -> Job? in
                let job = Job(id: doc.documentID, data: doc.data())
                if job == nil {
                    print("⚠️ Failed to decode completed job from doc: \(doc.documentID)")
                }
                return job
            }
            // Sort latest first
            .sorted { self.jobSortKey($0) > self.jobSortKey($1) }
            
            DispatchQueue.main.async {
                self.completedJobs = jobs
                print("✅ Fetched \(jobs.count) completed jobs for \(userRole) \(userId)")
            }
        }
    }
    
    // Add a new job posted by current user
    func addJob(_ job: Job, completion: ((Error?) -> Void)? = nil) {
        guard let currentUserID = currentUserID else {
            print("❌ Cannot post job — no authenticated user found.")
            completion?(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        let docRef = db.collection("jobs").document()
        
        // Create a copy of the job with correct poster ID and status
        var jobWithID = job
        jobWithID.id = docRef.documentID
        jobWithID.postedBy = currentUserID
        jobWithID.status = "open"
        
        // Set creation and expiry dates
        let now = Date()
        jobWithID.createdAt = now
        jobWithID.expiryDate = Calendar.current.date(byAdding: .hour, value: 24, to: now)
        
        // Add device's current location to geoLocation
        if let currentLocation = locationManager.location?.coordinate {
            jobWithID.geoLocation = GeoPoint(latitude: currentLocation.latitude,
                                             longitude: currentLocation.longitude)
        } else {
            print("⚠️ Could not get device location; job will not have geoLocation")
            // You can optionally handle this case (e.g., prevent posting until location is available)
        }
        
        let jobData = jobWithID.toDictionary()
        
        docRef.setData(jobData) { error in
            if let error = error {
                print("❌ Firestore error: \(error.localizedDescription)")
                completion?(error)
            } else {
                DispatchQueue.main.async {
                    self.activeJobs.append(jobWithID)
                    print("✅ Job successfully posted by \(currentUserID) with geoLocation: \(jobWithID.geoLocation)")
                    completion?(nil)
                }
            }
        }
    }
    
    
    // Mark a job as completed
    func completeJob(_ job: Job, completion: ((Error?) -> Void)? = nil) {
        db.collection("jobs").document(job.id).updateData(["status": "completed"]) { error in
            if let error = error {
                print("Error updating job status: \(error.localizedDescription)")
                completion?(error)
            } else {
                print("Job marked as completed: \(job.id)")
                completion?(nil)
            }
        }
    }
    
    // Delete a job document and cache it locally
    func deleteJob(_ job: Job, completion: ((Error?) -> Void)? = nil) {
        db.collection("jobs").document(job.id).delete { error in
            if let error = error {
                print("Error deleting job: \(error.localizedDescription)")
                completion?(error)
            } else {
                DispatchQueue.main.async {
                    self.deletedJobs.append(job)
                    print("Job deleted and added to deletedJobs: \(job.id)")
                }
                completion?(nil)
            }
        }
    }
    
    // Apply a candidate to a job, preventing duplicates using a transaction
    func applyToJob(job: Job, candidate: Candidate, completion: ((Error?) -> Void)? = nil) {
        let jobRef = db.collection("jobs").document(job.id)
        
        let newCandidateDict: [String: Any] = [
            "id": candidate.id,
            "name": candidate.name,
            "surname": candidate.surname,
            "experience": candidate.experience,
            "age": candidate.age,
            "number": candidate.number
        ]
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let jobDocument: DocumentSnapshot
            do {
                try jobDocument = transaction.getDocument(jobRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            let candidatesData = jobDocument.data()?["candidates"] as? [[String: Any]] ?? []
            
            // Prevent multiple applications from the same candidate
            if candidatesData.contains(where: { ($0["id"] as? String) == candidate.id }) {
                let error = NSError(domain: "", code: 409, userInfo: [NSLocalizedDescriptionKey : "You have already applied to this job."])
                errorPointer?.pointee = error
                return nil
            }
            
            transaction.updateData([
                "candidates": FieldValue.arrayUnion([newCandidateDict])
            ], forDocument: jobRef)
            
            return nil
        }) { (_, error) in
            if let error = error {
                print("Error applying candidate to job: \(error.localizedDescription)")
                completion?(error)
                return
            }
            
            print("Candidate successfully added to job")
            completion?(nil)
        }
    }
    
    // Accept a candidate for a job and generate a completion code
    func acceptCandidate(job: Job, candidate: Candidate, completion: ((Error?) -> Void)? = nil) {
        let jobRef = db.collection("jobs").document(job.id)
        
        let acceptedData: [String: Any] = [
            "id": candidate.id,
            "name": candidate.name,
            "surname": candidate.surname,
            "experience": candidate.experience,
            "age": candidate.age,
            "number": candidate.number
        ]
        
        let code = generateCompletionCode()
        
        jobRef.updateData([
            "status": "accepted",
            "acceptedCandidate": acceptedData,
            "acceptedWorkerId": candidate.id,
            "completionCode": code
        ]) { error in
            if let error = error {
                print("Error accepting candidate: \(error.localizedDescription)")
                completion?(error)
                return
            }
            
            print("Candidate accepted successfully")
            completion?(nil)
        }
    }
    
    func fetchEligibleWorkers(for job: Job, completion: @escaping ([Candidate]) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("users") // Make sure this is the collection storing workers
            .whereField("role", isEqualTo: "worker")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching eligible workers: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let docs = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let workers: [Candidate] = docs.compactMap { doc in
                    do {
                        let candidate = try doc.data(as: Candidate.self)
                        return candidate
                    } catch {
                        print("Failed to decode candidate \(doc.documentID): \(error.localizedDescription)")
                        return nil
                    }
                }
                
                let eligibleWorkers = workers.filter { worker in
                    if job.requiresDrivingLicense {
                        return worker.hasDrivingLicense
                    } else {
                        return true
                    }
                }
                
                completion(eligibleWorkers)
            }
    }
    
    func removeExpiredJobs() {
        let now = Date()
        
        db.collection("jobs")
            .whereField("status", isEqualTo: "open") // Only open jobs need expiry
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                for doc in documents {
                    if let timestamp = doc.data()["date"] as? Timestamp {
                        let jobDate = timestamp.dateValue()
                        if jobDate < now {
                            // Option 1: Delete the expired job
                            doc.reference.delete { error in
                                if let error = error {
                                    print("Error deleting expired job: \(error.localizedDescription)")
                                } else {
                                    print("Expired job deleted: \(doc.documentID)")
                                }
                            }
                            
                            // Option 2: Or mark it as expired instead
                            /*
                             doc.reference.updateData(["status": "expired"]) { error in
                             if let error = error {
                             print("Error marking job expired: \(error.localizedDescription)")
                             } else {
                             print("Job marked as expired: \(doc.documentID)")
                             }
                             }
                             */
                        }
                    }
                }
            }
    }
    
    func distanceInMiles(from jobGeo: GeoPoint, to user: CLLocation) -> Double {
        let jobLocation = CLLocation(latitude: jobGeo.latitude, longitude: jobGeo.longitude)
        return jobLocation.distance(from: user) / 1609.34
    }
    
    func nearbyOpenJobs(userLocation: CLLocation, maxDistanceMiles: Double) -> [Job] {
        businessadvertisedJobs.filter { job in
            return distanceInMiles(from: job.geoLocation, to: userLocation) <= maxDistanceMiles
        }
    }
    
    func workerMatchesJob(job: Job, worker: Candidate) -> Bool {
        
        // Driving licence check
        if job.requiresDrivingLicense && !worker.hasDrivingLicense {
            return false
        }
        
        // Skill match: job skills must be subset of worker skills
        let workerSkills = Set(worker.skills)
        let jobSkills = Set(job.requiredSkills)
        
        return jobSkills.isSubset(of: workerSkills)
    }
    
    func updateEligibleJobs(
        worker: Candidate,
        userLocation: CLLocation,
        maxDistanceMiles: Double = 5
    ) {
        eligibleJobs = businessadvertisedJobs.filter { job in
            // distance check
            let jobLocation = CLLocation(
                latitude: job.geoLocation.latitude,
                longitude: job.geoLocation.longitude
            )
            
            let distanceMiles = jobLocation.distance(from: userLocation) / 1609.34
            guard distanceMiles <= maxDistanceMiles else { return false }
            
            // skill match
            return job.requiredSkills.isEmpty ||
            !Set(job.requiredSkills)
                .intersection(worker.skills)
                .isEmpty
        }
        // Sort latest posted first
        .sorted { jobSortKey($0) > jobSortKey($1) }
    }

    // Returns a date to sort jobs by "latest posted first".
    // Prefers createdAt; falls back to expiryDate (which is createdAt + 24h) for older jobs.
    private func jobSortKey(_ job: Job) -> Date {
        if let created = job.createdAt { return created }
        if let expiry = job.expiryDate { return expiry }
        return Date.distantPast
    }
    
    func fetchCurrentCandidate(userId: String) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("❌ Failed to fetch candidate: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else {
                print("❌ No candidate document found")
                return
            }
            
            // Read using the actual field names saved at signup / profile.
            // Fall back to alternate keys for robustness across older/newer docs.
            let firstName = data["firstName"] as? String ?? data["name"] as? String ?? ""
            let lastName = data["lastName"] as? String ?? data["surname"] as? String ?? ""
            let phone = data["mobileNumber"] as? String
                ?? data["mobilePhoneNumber"] as? String
                ?? data["number"] as? String ?? ""

            let candidate = Candidate(
                id: userId,
                name: firstName,
                surname: lastName,
                experience: data["experience"] as? String ?? "Not specified",
                age: data["age"] as? Int ?? 0,
                number: phone,
                skills: data["skills"] as? [String] ?? [],
                hasDrivingLicense: data["hasDrivingLicense"] as? Bool ?? false
            )
            
            DispatchQueue.main.async {
                self.currentCandidate = candidate
                print("✅ Loaded candidate: \(candidate.name) \(candidate.surname)")
            }
        }
    }
    
    
    // Generates a random 6-character alphanumeric code
    func generateCompletionCode(length: Int = 6) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    // Verify completion code input and mark job as completed if matched
    func verifyCompletionCode(job: Job, inputCode: String, completion: ((Bool, Error?) -> Void)? = nil) {
        guard let correctCode = job.completionCode else {
            completion?(false, NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "No completion code found."]))
            return
        }
        
        if inputCode.uppercased() == correctCode.uppercased() {
            self.completeJob(job) { error in
                if let error = error {
                    completion?(false, error)
                } else {
                    completion?(true, nil)
                }
            }
        } else {
            completion?(false, NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Incorrect code."]))
        }
    }
    
}
