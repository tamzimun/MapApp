//
//  ViewController.swift
//  MapApp4
//
//  Created by tamzimun on 27.06.2022.
//

import UIKit
import CoreData
import MapKit

class MainViewController: UIViewController {
    
    private var coreDataPlaces: [NSManagedObject] = []
    
    private var pinAnnotations: [MKPointAnnotation] = []
    
    private var editLocation: MKAnnotation!
    
    private let tableView = UITableView()
    
    private let mapView: MKMapView = {
        let map = MKMapView()
        map.overrideUserInterfaceStyle = .light
        return map
    }()
    
    private let bottomView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .light)
        let view = UIVisualEffectView(effect: blurEffect)
        return view
    }()
        
    private lazy var segmentedControl: UISegmentedControl = {
        let segmented = UISegmentedControl (items: ["Standard","Satelite","Hybrid"])
        segmented.frame = CGRect()
        segmented.selectedSegmentIndex = 0
        segmented.backgroundColor = .clear
        segmented.addTarget(self, action: #selector(segmentAction(_:)), for: .valueChanged)
        return segmented
    }()
    
    private lazy var forward: UIButton = {
        let button = ChangeLocationButton(arrowString: "→")
        button.tag = 0
        button.addTarget(self, action: #selector(handleForwardBackwardContact), for: .touchUpInside)
        return button
    }()
    
    private lazy var backward: UIButton = {
        let button = ChangeLocationButton(arrowString: "←")
        button.tag = 1
        button.addTarget(self, action: #selector(handleForwardBackwardContact), for: .touchUpInside)
        return button
    }()

    private var placeIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    
        loadPlaces()
        convertValuesFromCoreDate()
        longPress()
        
        setMapConstraints()
        setBottomViewConstraints()
        setSegConForwardBackwardConstraints()
        setUpNaviagtion()
        setupTableView()
        
        mapView.delegate = self
    }

    // MARK: - ConvertValuesFromCoreDate
    
    func convertValuesFromCoreDate() {
        if coreDataPlaces.isEmpty != true { return }
        for object in coreDataPlaces {
            let pin = MKPointAnnotation()
            pin.coordinate.longitude = object.value(forKeyPath: "longitude") as! CLLocationDegrees
            pin.coordinate.latitude = object.value(forKeyPath: "latitude") as! CLLocationDegrees
            pin.title = object.value(forKeyPath: "title") as? String
            pin.subtitle = object.value(forKeyPath: "subtitle") as? String
            pinAnnotations.append(pin)
            
        }
        tableView.reloadData()
    }
    
    // MARK: - Setup NavigationController
    
    func setUpNaviagtion() {
        tableView.isHidden = true
        navigationItem.title = ""
        self.navigationController?.view.backgroundColor = .white
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(handleOrganizePlace))
    }
    
    fileprivate func longPress() {
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressRecognizer.minimumPressDuration = 0.5
        view.addGestureRecognizer(longPressRecognizer)
    }
    
    // MARK: - @objc
    
    @objc
    func segmentAction(_ sender: UISegmentedControl) {
        
        let index = sender.selectedSegmentIndex
        
        switch index {
        case 0:
            mapView.mapType = .standard
        case 1:
            mapView.mapType = .satellite
        case 2:
            mapView.mapType = .hybrid
        default:
            break
        }
    }
    
    @objc
    func handleForwardBackwardContact(_ sender: UIButton) {
        
        if placeIndex < 0 {
            placeIndex = coreDataPlaces.count - 1
        } else if placeIndex >= coreDataPlaces.count  {
            placeIndex = 0
        }
        

        mapView.setRegion(MKCoordinateRegion(center: pinAnnotations[placeIndex].coordinate, span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)), animated: false)
        
        title = pinAnnotations[placeIndex].title
        
        switch sender.tag {
        case 0:
            placeIndex += 1
        case 1:
            placeIndex -= 1
        default:
            break
        }
    }
    
    @objc
    func handleOrganizePlace () {
        self.view.bringSubviewToFront(tableView)
        tableView.isHidden.toggle()
    }

    @objc
    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state != UIGestureRecognizer.State.ended {
        
            // Add pin
            let touchLocation = gestureReconizer.location(in: mapView)
            let locationCoordinate = mapView.convert(touchLocation,toCoordinateFrom: mapView)
            let pin = MKPointAnnotation()
            pin.coordinate = CLLocationCoordinate2D(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude)
           
            // Alert to add place
            callAlert(pin)
    
        return
      }
        if gestureReconizer.state != UIGestureRecognizer.State.began { return }
    }
    
    fileprivate func callAlert(_ pin: MKPointAnnotation) {
        
        let alert = UIAlertController(title: "Add place", message: "Fill all the fields", preferredStyle: .alert)
        alert.addTextField { (textField:UITextField) in
            textField.placeholder = "Enter title"
        }
        alert.addTextField { (textField:UITextField) in
            textField.placeholder = "Enter subtitle"
        }
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [self] (action:UIAlertAction) in
            guard let textField =  alert.textFields?.first, ((alert.textFields?.first?.hasText) != nil) else {
                return
            }
            guard let textField2 =  alert.textFields?[1], ((alert.textFields?[1].hasText) != nil) else {
                return
            }
            
            pin.subtitle = textField2.text
            pin.title = textField.text
            pinAnnotations.append(pin)
            mapView.addAnnotation(pin)
            savePlace(pin.title!, pin.subtitle!, pin.coordinate.longitude,   pin.coordinate.latitude)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - CoreData
    
    func loadPlaces(){
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Place")
        
        do {
            coreDataPlaces = try managedContext.fetch(fetchRequest)
            
            for storedLocation in coreDataPlaces {
                let newAnnotation = MKPointAnnotation()
                newAnnotation.coordinate.latitude = storedLocation.value(forKeyPath: "latitude") as! CLLocationDegrees
                newAnnotation.coordinate.longitude = storedLocation.value(forKeyPath: "longitude") as! CLLocationDegrees
                newAnnotation.title = storedLocation.value(forKeyPath: "title") as? String
                newAnnotation.subtitle = storedLocation.value(forKeyPath: "subtitle") as? String
                pinAnnotations.append(newAnnotation)
            }
            mapView.addAnnotations(pinAnnotations)
            
        } catch let error as NSError {
          print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    //Добавить место в CoreData
    func savePlace(_ title: String,
                   _ subtitle: String,
                   _ longitude: Double,
                   _ latitude: Double)
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "Place", in: managedContext)!
        let place = NSManagedObject(entity: entity, insertInto: managedContext)
        
        place.setValue(title, forKeyPath: "title")
        place.setValue(subtitle, forKeyPath: "subtitle")
        place.setValue(longitude, forKeyPath: "longitude")
        place.setValue(latitude, forKeyPath: "latitude")
        
        do {
            try managedContext.save()
            
            tableView.reloadData()
        } catch let error as NSError {
          print("Could not save. \(error), \(error.userInfo)")
        }
    }

    
    //Удалить место с CoreData
    func deletePlace(_ title: String?, _ subtitle: String?, _ longitude: Double?, _ latitude: Double?){
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Place")
        
        let p1 = NSPredicate(format: "title == %@", title!)
        let p2 = NSPredicate(format: "subtitle == %@", subtitle!)
        let p3 = NSPredicate(format: "longitude == %lf", longitude!)
        let p4 = NSPredicate(format: "latitude == %lf", latitude!)
        
        let p_and = NSCompoundPredicate(type: .and, subpredicates: [p1, p2, p3, p4])
        fetchRequest.predicate = p_and
        do{
            let results = try managedContext.fetch(fetchRequest)
            let data = results.first
            managedContext.delete(data!)
            try managedContext.save()
        }catch {
            print ("fetch task failed", error)
        }
    }
    
    // MARK: - Setup Constraints
    
    private func setMapConstraints() {
        view.addSubview(mapView)
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor ).isActive = true
        mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    private func setBottomViewConstraints() {
        view.addSubview(bottomView)
        
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.bottomAnchor.constraint(equalTo: mapView.bottomAnchor).isActive = true
        bottomView.leadingAnchor.constraint(equalTo: mapView.leadingAnchor).isActive = true
        bottomView.trailingAnchor.constraint(equalTo: mapView.trailingAnchor).isActive = true
        bottomView.heightAnchor.constraint(equalToConstant: 95).isActive = true
    }
    
    private func setSegConForwardBackwardConstraints() {
        view.addSubview(forward)
        view.addSubview(segmentedControl)
        view.addSubview(backward)
        
        backward.translatesAutoresizingMaskIntoConstraints = false
        backward.topAnchor.constraint(equalTo: bottomView.topAnchor, constant: 20).isActive = true
        backward.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: 20).isActive = true
        backward.heightAnchor.constraint(equalToConstant: 40).isActive = true
        backward.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.topAnchor.constraint(equalTo: bottomView.topAnchor, constant: 25).isActive = true
        segmentedControl.leadingAnchor.constraint(equalTo: backward.trailingAnchor, constant: 20).isActive = true
        segmentedControl.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        
        forward.translatesAutoresizingMaskIntoConstraints = false
        forward.topAnchor.constraint(equalTo: bottomView.topAnchor, constant: 20).isActive = true
        forward.leadingAnchor.constraint(equalTo: segmentedControl.trailingAnchor, constant: 20).isActive = true
        forward.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -20).isActive = true
        forward.heightAnchor.constraint(equalToConstant: 40).isActive = true
        forward.widthAnchor.constraint(equalToConstant: 40).isActive = true
    }

    private func setupTableView() {
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        tableView.register(PlaceTableViewCell.self, forCellReuseIdentifier: "PlaceTableViewCell")
        tableView.delegate = self
        tableView.dataSource = self
    }
}


// MARK: - UITableViewDataSource, UITableViewDelegate

extension MainViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pinAnnotations.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceTableViewCell", for: indexPath) as! PlaceTableViewCell
        cell.titleLabel.text = pinAnnotations[indexPath.row].title
        cell.subtitleLabel.text = pinAnnotations[indexPath.row].subtitle
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        85
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
            let place = pinAnnotations[indexPath.row]
            deletePlace(place.title, place.subtitle, place.coordinate.longitude, place.coordinate.latitude)
            mapView.removeAnnotation(place)
            pinAnnotations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        view.sendSubviewToBack(tableView)
        mapView.setRegion(MKCoordinateRegion(center: pinAnnotations[indexPath.row].coordinate, span: MKCoordinateSpan(latitudeDelta: 7, longitudeDelta: 7)), animated: false)
        title = pinAnnotations[placeIndex].title
    }
}


// MARK: - MKMapViewDelegate

extension MainViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "customAnnotation") as? MKPinAnnotationView
        if annotationView == nil {

            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "customAnnotation")
            annotationView?.canShowCallout = true
            annotationView?.animatesDrop = true
            let calloutButton = UIButton(type: .detailDisclosure)
            annotationView!.rightCalloutAccessoryView = calloutButton
            annotationView!.sizeToFit()
        }
        else {
            annotationView!.annotation = annotation
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let vc = EditViewController()
        vc.titleField.text = pinAnnotations[placeIndex].title
        vc.subtitleField.text = pinAnnotations[placeIndex].subtitle
        vc.editDelegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let annotation = view.annotation
        if let title = annotation?.title {
            let titles = pinAnnotations.map { $0.title }
            let index = titles.firstIndex(of: title)!
            placeIndex = index
        }
        editLocation = annotation
    }
}

// MARK: - EditPlaceDelegate

extension MainViewController: EditPlaceDelegate {
    func editPlace(title: String, subtitle: String) {
        if let index = pinAnnotations.firstIndex(of: editLocation as! MKPointAnnotation) {
            deletePlace(pinAnnotations[placeIndex].title, pinAnnotations[placeIndex].subtitle, pinAnnotations[index].coordinate.longitude, pinAnnotations[index].coordinate.latitude)
            
            pinAnnotations[index].title = title
            pinAnnotations[index].subtitle = subtitle
            tableView.reloadData()
           
            savePlace(pinAnnotations[index].title!, pinAnnotations[index].subtitle!, pinAnnotations[index].coordinate.longitude, pinAnnotations[index].coordinate.latitude)
        }
    }
    
}

private extension MainViewController{}
