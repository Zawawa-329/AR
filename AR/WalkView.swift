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
    @Published var heading: CLLocationDirection?
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            DispatchQueue.main.async {
                self.location = loc.coordinate
            }
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
          DispatchQueue.main.async {
               self.heading = newHeading.trueHeading // 北を0°とする角度
           }
       }
}

struct ArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        // 扇形を描画（中心角90°）
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: .degrees(-45), endAngle: .degrees(45), clockwise: false)
        path.closeSubpath()
        return path
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
    @State private var route: MKRoute? = nil



    //関数ゾーン
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
    
    private func calculateRoute() {
        guard let start = locationManager.location, let dest = destination else { return }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: dest))
        request.transportType = .walking //お散歩

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let route = response?.routes.first {
                DispatchQueue.main.async {
                    self.route = route
                }
            }
        }
    }



    //ボタン系ゾーン
    var body: some View {
        
        ZStack(alignment: .topLeading) {
            Map(position: $cameraPosition) {
                if let loc = locationManager.location {
                    Annotation("", coordinate: loc) {
                        ZStack {
                            // ✅ 小さめの扇形（青い光）
                            ArcShape()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 70, height: 70) // ← 小さめ
                                .rotationEffect(Angle(degrees: locationManager.heading ?? 0))
                                .animation(.easeInOut(duration: 0.2), value: locationManager.heading)

                            // ✅ 現在地アイコン
                            Image("map_aicon")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        }
                        // ✅ 中央補正
                        .offset(x: -35 + 20, y: -35 + 20)
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
                if let route = route {
                       MapPolyline(route.polyline)
                           .stroke(Color.blue, lineWidth: 5)
                   }
            }
            .zIndex(0)


            
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
                .padding(.top, 50)//位置について
                
                Spacer()
            }
            .zIndex(10)
            
            if let route = route {
                VStack {
                    HStack {
                        Text("距離: \(String(format: "%.1f", route.distance / 1000)) km")
                            .font(.headline)
                        Spacer()
                        Text("かかる時間: \(Int(route.expectedTravelTime / 60)) 分")
                            .font(.headline)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .shadow(radius: 3)
                    .padding(.horizontal)
                    .padding(.top, 140) // ✅ 検索バーの下に配置
                    Spacer()
                }
                .transition(.move(edge: .top))
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
                            calculateRoute()
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
                .zIndex(100)//最前面
            }

            if let mode = selectedMode {
                ZStack(alignment: .topTrailing) {
                    switch mode {
                    case .care: CareView().background(Color.white).ignoresSafeArea()
                    case .sleep: SleepView().background(Color.white).ignoresSafeArea()
                    case .dressUp: DressUpView().background(Color.white).ignoresSafeArea()
                    case .content: ContentView().background(Color.white).ignoresSafeArea()
                    }

                    // 戻るボタンを追加
                    Button(action: { selectedMode = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                .zIndex(100)//最前面
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

