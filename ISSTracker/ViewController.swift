//
//  ViewController.swift
//  ISSTracker
//
//  Created by Seif Kobrosly on 9/14/22.
//

import UIKit
import MapKit

class ViewController: UIViewController {

    let IDENTIFIER = "ISS_ANNOTATION"
    private var apiTimer = Timer()
    private var geodesicPolyline:MKGeodesicPolyline?
    private var issLocationPath:[CLLocationCoordinate2D] = []
    private let floatingButton = UIButton()
    private let mapView : MKMapView = {
        let map = MKMapView()
        map.mapType = .satelliteFlyover
        map.overrideUserInterfaceStyle = .dark
        return map
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.mapView.delegate = self
        self.mapView.register(ISSAnnotation.self, forAnnotationViewWithReuseIdentifier: IDENTIFIER)
        self.setupUI()
        self.setupConstraints()
        self.animateISS(completion: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.apiTimer.invalidate()
    }

    func animateISS(completion: (() -> Void)?) {
        var firstLaunch = true
        self.apiTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: { [weak self] timer in
            guard let self = self else {
                // Invalidate timer if we can't retain self
                timer.invalidate()
                completion?()
                return
            }
            self.fetchISSLocation { currentISSLocation, error in
                if let currentLocation = currentISSLocation {

                    self.issLocationPath.append(currentLocation.issPosition.locationCoordinate())

                    let annotation = ISSAnnotation(coordinate: (currentLocation.issPosition.locationCoordinate()), title: "ISS", subtitle: String(currentLocation.timestamp))

                    self.geodesicPolyline = MKGeodesicPolyline(coordinates: self.issLocationPath, count: self.issLocationPath.count)

                    DispatchQueue.main.async {
                        if firstLaunch {
                            self.mapView.addAnnotation(annotation)
                            self.mapView.setCenter(currentLocation.issPosition.locationCoordinate(), animated: true)
                            firstLaunch = false
                        }

                        UIView.animate(withDuration: 0.3) {
                            self.mapView.annotations
                                .compactMap { $0 as? ISSAnnotation }
                                .forEach { existingMarker in
                                    existingMarker.setCoordinate(newCoordinate: currentLocation.issPosition.locationCoordinate())
                                    existingMarker.subtitle = self.toStringFromUnix(unixTime: currentLocation.timestamp)
                                    existingMarker.title = self.coord2String(location: currentLocation.issPosition.locationCoordinate())
                            }
                        }
                        if let polyLine = self.geodesicPolyline {
                            self.mapView.addOverlay(polyLine)
                            self.geodesicPolyline = nil
                        }
                    }
                }
                if error != nil {
                    DispatchQueue.main.async {
                        let alert = UIAlertController.errorAlert(error: error!, onConfirmation: {
                            timer.invalidate()
                            completion?()
                        })
                        self.present(alert, animated: true)
                    }
                }
            }
        })
    }

    func fetchISSLocation(onCompletionHandler: @escaping (ISSNow?, Error?) -> ()) {
        let tracker = ISSTracker()
        let serialQueue = DispatchQueue(label: "reload-network", attributes: .concurrent)
        serialQueue.async {
            tracker.retrieveJSONISSLocation { dictionary, error in
                if let dict = dictionary as? Dictionary<String, Any> {
                    let jsonData = try? JSONSerialization.data(withJSONObject: dict)
                    if let data = jsonData {
                        let serverResponse = try? JSONDecoder().decode(ISSNow.self, from: data)
                        onCompletionHandler(serverResponse, nil)
                    }
                }
                if error != nil {
                    onCompletionHandler(nil, error)
                }
            }
        }

    }
}


extension ViewController: MKMapViewDelegate {

    // MARK: UI
    func setupUI() {
        self.view.backgroundColor = .white
        self.view.addSubview(mapView)

        let largeConfig = UIImage.SymbolConfiguration(pointSize: 48, weight: .bold, scale: .large)
        let largeBoldDoc = UIImage(systemName: "location.circle.fill", withConfiguration: largeConfig)
        self.floatingButton.translatesAutoresizingMaskIntoConstraints = false
        self.floatingButton.setImage(largeBoldDoc, for: .normal)
        self.floatingButton.tintColor = .white
        self.floatingButton.layer.cornerRadius = 25
        self.floatingButton.layer.shadowColor = UIColor.systemBackground.cgColor
        self.floatingButton.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        self.floatingButton.layer.shadowOpacity = 0.2
        self.floatingButton.layer.shadowRadius = 4.0
        self.floatingButton.layer.masksToBounds = true
        self.floatingButton.addTarget(self, action: #selector(centerISSOnMap(_:)), for: .touchUpInside)
        self.mapView.addSubview(self.floatingButton)

    }

    func setupConstraints() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        mapView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true

        floatingButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        floatingButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        floatingButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -25).isActive = true
        floatingButton.bottomAnchor.constraint(equalTo: mapView.layoutMarginsGuide.bottomAnchor, constant: -20).isActive = true
    }


    @objc
    func centerISSOnMap(_ sender: UIButton) {
        if let lastLocation = self.issLocationPath.last {
            self.mapView.setCenter(lastLocation, animated: true)
        }
    }

    // MARK: MapKit Delegates
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        // Make sure we are rendering a polyline.
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer()
        }

        // Create a specialized polyline renderer and set the polyline properties.
        let polylineRenderer = MKPolylineRenderer(overlay: polyline)
        polylineRenderer.strokeColor = .systemYellow
        polylineRenderer.lineWidth = 2
        return polylineRenderer
    }


    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
          let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: IDENTIFIER)

          annotationView.canShowCallout = true
          if annotation is MKUserLocation {
             return nil
          } else if annotation is ISSAnnotation {
             annotationView.image =  UIImage(imageLiteralResourceName: "iss-icon")
              annotationView.tintColor = .white
             return annotationView
          } else {
             return nil
          }
       }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapView.setNeedsDisplay()
    }


    // MARK: Helper Functions
    private func coord2String(location : CLLocationCoordinate2D) -> String {
        return  String(format : "ISS: %f, %f", location.latitude, location.longitude)
    }

    private func toStringFromUnix(unixTime: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(unixTime))
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.medium
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeZone = .current
        return dateFormatter.string(from: date)
    }

}


extension UIAlertController {
    static func errorAlert(error: Error, onConfirmation: @escaping () -> Void) -> UIAlertController {
        let ok = UIAlertAction(title: "OK", style: .default) { _ in onConfirmation() }
        let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(ok)
        return alert
    }
}
