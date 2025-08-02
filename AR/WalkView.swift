//
//  WalkView.swift
//  AR
//
//  Created by owner on 2025/08/01.
//

import SwiftUI
import RealityKit
import MapKit
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocationCoordinate2D?
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            DispatchQueue.main.async {
                self.location = loc.coordinate
            }
        }
    }
}


struct WalkView: View {
    @State private var isMenuOpen = false
    @State private var selectedMode: Mode? = nil
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.6804, longitude: 139.7690),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    @State private var didCenterOnUserLocation = false
    @State private var searchQuery = ""
    @State private var destination: CLLocationCoordinate2D? = nil
    @State private var pendingDestination: CLLocationCoordinate2D? = nil
    @State private var showConfirmDestination = false
    @FocusState private var isSearchFocused: Bool


    
    //住所検索
    private func searchAddress() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        request.region = MKCoordinateRegion(
            center: locationManager.location ?? CLLocationCoordinate2D(latitude: 35.6804, longitude: 139.7690),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let placemark = response?.mapItems.first?.placemark, error == nil else { return }
            DispatchQueue.main.async {
                pendingDestination = placemark.coordinate
                            withAnimation {
                                cameraPosition = .region(MKCoordinateRegion(
                                    center: placemark.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                ))
                            }
                    }
        }
    }

    enum Mode {
        case care, sleep, dressUp, content
    }
    
    //現在地に戻る処理関数
    private func centerOnUserLocation() {
        if let loc = locationManager.location {
            withAnimation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: loc,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
    }


    var body: some View {
        
        ZStack(alignment: .topLeading) {
            Map(position: $cameraPosition) {
                if let loc = locationManager.location {
                    Annotation("", coordinate: loc) {
                        Image("map_aicon")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    }
                }
                
                if let dest = destination {
                      Annotation("目的地", coordinate: dest) {
                           Image(systemName: "mappin.and.ellipse")
                               .font(.system(size: 40))
                               .foregroundColor(.red)
                       }
                   }
                if let pending = pendingDestination {
                        Annotation("", coordinate: pending) {
                            Image(systemName: "mappin")
                                .font(.system(size: 36))
                                .foregroundColor(.blue)
                        }
                    }
            }


            
            Button(action: {
                withAnimation {
                    isMenuOpen.toggle()
                }
            }) {
                Image(systemName: "line.3.horizontal")
                    .resizable()
                    .frame(width: 30, height: 20)
                    .foregroundColor(Color.green)
                    .padding()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()
            
            //現在地に戻るボタン
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        centerOnUserLocation()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
            }
            
            //検索バー
            VStack {
                HStack {
                    TextField("住所を入力", text: $searchQuery)
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .focused($isSearchFocused)

                    
                    Button(action: {
                        searchAddress()
                        isSearchFocused = false
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                            .padding(10)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
            }
            
            //目的地決定
            if let pending = pendingDestination {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            destination = pending
                            pendingDestination = nil // 確定後は消す
                        }) {
                            Text("この場所を目的地にする")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 80) // 現在地ボタンより上に配置
                    }
                }
            }



            

            if isMenuOpen {
                VStack(alignment: .leading, spacing: 20) {
                    Button("お世話") { selectedMode = .care; isMenuOpen = false} .foregroundColor(Color.green)
                    Button("おやすみ") { selectedMode = .sleep; isMenuOpen = false} .foregroundColor(Color.green)
                    Button("お着替え") { selectedMode = .dressUp; isMenuOpen = false} .foregroundColor(Color.green)
                    Button("ホーム") { selectedMode = .content; isMenuOpen = false} .foregroundColor(Color.green)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding(.top, 70)
                .padding(.leading, 10)
                .transition(.move(edge: .leading))
            }

            if let mode = selectedMode {
                switch mode {
                case .care: CareView()
                case .sleep: SleepView()
                case .dressUp: DressUpView()
                case .content: ContentView()
                }
            }


        }
        .onChange(of: locationManager.location?.latitude) {
            if let loc = locationManager.location, !didCenterOnUserLocation {
                withAnimation {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: loc,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                    didCenterOnUserLocation = true //一度だけ
                }
            }
        }


    }
}

