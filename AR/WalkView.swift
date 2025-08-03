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
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation  // 高精度
        manager.distanceFilter = 0.5  // 1mごとに更新
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
            self.heading = newHeading.trueHeading
        }
    }
}

struct ArcShape: Shape {
    var heading: Double // heading を保持

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)

        let arcSpan: Double = 90 // 扇形の角度
        let correctedHeading = -(heading - 90) // 90°補正＆反転

        let startAngle = Angle(degrees: correctedHeading - arcSpan / 2)
        let endAngle = Angle(degrees: correctedHeading + arcSpan / 2)

        path.move(to: center)
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)
        path.closeSubpath()

        return path
    }
}






struct WalkView: View {
    @State private var isMenuOpen = false
    @State private var selectedMode: Mode? = nil
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 35.6804, longitude: 139.7690),
                           span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    )
    @State private var didCenterOnUserLocation = false
    @State private var searchQuery = ""
    @State private var destination: CLLocationCoordinate2D? = nil
    @State private var pendingDestination: CLLocationCoordinate2D? = nil
    @FocusState private var isSearchFocused: Bool
    @State private var route: MKRoute? = nil
    @State private var suggestions: [(item: MKMapItem, distance: Double, time: Double)] = []
    @State private var isSuggesting = false
    @State private var selectedCategory: String = "すべて"
    @State private var selectedSuggestion: (item: MKMapItem, distance: Double, time: Double)? = nil
    @State private var fromSuggestion = false
    @State private var hasArrived = false
    
    enum Mode {
        case care, sleep, dressUp, content
    }
    
    private func searchAddress() {
        destination = nil
        pendingDestination = nil
        selectedSuggestion = nil
        route = nil

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        request.region = MKCoordinateRegion(center: locationManager.location ?? CLLocationCoordinate2D(latitude: 35.6804, longitude: 139.7690),
                                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let mapItem = response?.mapItems.first, error == nil else { return }
            DispatchQueue.main.async {
                fromSuggestion = false
                pendingDestination = mapItem.placemark.coordinate
                searchQuery = ""
                isSuggesting = false

                withAnimation(.linear(duration: 0.2)) {
                    cameraPosition = .region(MKCoordinateRegion(center: mapItem.placemark.coordinate,
                                                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
                }

                // ✅ MKDirectionsで距離・時間を取得してからselectedSuggestionをセット
                calculateSelectedSuggestionDetails(for: mapItem)
            }
        }
    }


    
    
    private func centerOnUserLocation() {
        if let loc = locationManager.location {
            withAnimation(.linear(duration: 0.2)) {
                cameraPosition = .region(MKCoordinateRegion(center: loc,
                                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
            }
        }
    }
    
    private func calculateRoute() {
        guard let start = locationManager.location, let dest = destination else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: dest))
        request.transportType = .walking
        
        MKDirections(request: request).calculate { response, error in
            if let route = response?.routes.first {
                DispatchQueue.main.async {
                    self.route = route
                }
            }
        }
    }
    
    private func calculateSelectedSuggestionDetails(for mapItem: MKMapItem) {
        guard let start = locationManager.location else { return }
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = mapItem
        request.transportType = .walking

        MKDirections(request: request).calculate { response, error in
            if let route = response?.routes.first {
                DispatchQueue.main.async {
                    selectedSuggestion = (item: mapItem, distance: route.distance, time: route.expectedTravelTime)
                }
            }
        }
    }

    
    private func suggestDestinations(category: String?) {
        guard let userLocation = locationManager.location else { return }

        DispatchQueue.main.async {
            // ✅ 検索開始時に即クリア
            self.suggestions = []
            self.isSuggesting = true
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = category ?? "観光スポット"
        request.region = MKCoordinateRegion(center: userLocation,
                                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))

        MKLocalSearch(request: request).start { response, error in
            guard let items = response?.mapItems, error == nil else {
                DispatchQueue.main.async {
                    self.isSuggesting = false
                }
                return
            }

            let limitedItems = Array(items.prefix(10))
            let results = limitedItems.map { item -> (item: MKMapItem, distance: Double, time: Double) in
                let distance = CLLocation(latitude: userLocation.latitude,
                                          longitude: userLocation.longitude)
                    .distance(from: CLLocation(latitude: item.placemark.coordinate.latitude,
                                               longitude: item.placemark.coordinate.longitude))
                let estimatedTime = (distance / 80) // 徒歩時速4.8km/h → 約80m/分
                return (item, distance, estimatedTime * 60)
            }

            DispatchQueue.main.async {
                self.suggestions = results
                    .filter { $0.time / 60 >= 10 && $0.time / 60 <= 30 }
                    .sorted(by: { $0.distance < $1.distance })
            }
        }
    }
    
    private func checkArrival() {
        guard let current = locationManager.location,
              let target = destination else {
            hasArrived = false
            return
        }
        
        let userLocation = CLLocation(latitude: current.latitude, longitude: current.longitude)
        let destinationLocation = CLLocation(latitude: target.latitude, longitude: target.longitude)
        
        if userLocation.distance(from: destinationLocation) <= 20 {
            hasArrived = true
        } else {
            hasArrived = false
        }
    }





    
    // ✅ 順次処理でMKDirections計算
    private func suggestDestinationsSequentially(items: [MKMapItem], userLocation: CLLocationCoordinate2D) {
        var results: [(item: MKMapItem, distance: Double, time: Double)] = []
        
        func processNext(index: Int) {
            guard index < items.count else {
                DispatchQueue.main.async {
                    self.suggestions = results
                        .filter { $0.time / 60 >= 5 && $0.time / 60 <= 30 } // ✅ 5〜30分
                        .sorted(by: { $0.distance < $1.distance })           // ✅ 距離で並び替え
                    self.isSuggesting = true
                }
                return
            }
            
            let item = items[index]
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
            request.destination = item
            request.transportType = .walking
            
            MKDirections(request: request).calculate { response, error in
                defer {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) { // ✅ 間隔少し短縮
                        processNext(index: index + 1)
                    }
                }
                
                guard error == nil, let route = response?.routes.first else { return }
                results.append((item, route.distance, route.expectedTravelTime))
            }
        }
        
        processNext(index: 0)
    }

    
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // ✅ MapやUIはお散歩モードのみ表示
            if selectedMode == nil {
                mapView
                menuButton
                currentLocationButton
                destinationSearchButton
                suggestionOverlay
                searchBar
                detailSheet
                removeDestinationButton
                arrivalButton

                
                if isMenuOpen {
                    VStack(alignment: .leading, spacing: 20) {
                        Button("お世話") { selectedMode = .care; isMenuOpen = false }
                        Button("おやすみ") { selectedMode = .sleep; isMenuOpen = false }
                        Button("お着替え") { selectedMode = .dressUp; isMenuOpen = false }
                        Button("ホーム") { selectedMode = .content; isMenuOpen = false }
                    }
                    .padding()
                    .background(Color.white.opacity(0.9)) // ✅ 背景を半透明に変更（AR透過）
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding(.top, 70)
                    .padding(.leading, 10)
                    .transition(.move(edge: .leading))
                    .zIndex(100)
                }
            }
            
            // ✅ 他モード（ARや他画面）はZStackの下に出せばOK
            if let mode = selectedMode {
                switch mode {
                case .care:
                    CareView() // ARのViewがここなら、そのまま表示される
                case .sleep:
                    SleepView()
                case .dressUp:
                    DressUpView()
                case .content:
                    ContentView()
                }
            }
        }
        .onChange(of: locationManager.location?.latitude) {
            if let loc = locationManager.location, !didCenterOnUserLocation {
                withAnimation(.linear(duration: 0.2)) {
                    cameraPosition = .region(MKCoordinateRegion(center: loc,
                                                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
                    didCenterOnUserLocation = true
                }
            }
        }
        .onChange(of: "\(locationManager.location?.latitude ?? 0),\(locationManager.location?.longitude ?? 0)") { _ in
            checkArrival()
        }
        .onChange(of: selectedCategory) {
            suggestDestinations(category: selectedCategory == "すべて" ? nil : selectedCategory)
        }

    }


}

    
    extension WalkView {
    private var mapView: some View {
        Map(position: $cameraPosition) {
            if let loc = locationManager.location {
                Annotation("", coordinate: loc) {
                    ZStack {
                        ArcShape(heading: locationManager.heading ?? 0)
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 70, height: 70)
                            .animation(.easeInOut(duration: 0.2), value: locationManager.heading)
                            .rotationEffect(Angle(degrees: locationManager.heading ?? 0))
                        Image("map_aicon")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    }
                }
            }
            if let dest = destination {
                Annotation("目的地", coordinate: dest) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 36))
                        .foregroundColor(.red)
                }
            }
            if let pending = pendingDestination {
                Annotation("", coordinate: pending) {
                    Image(systemName: "mappin")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
            }
            if let route = route {
                MapPolyline(route.polyline)
                    .stroke(Color.blue, lineWidth: 4)
            }
        }
    }
    
    private var menuButton: some View {
        VStack {
            HStack {
                Button(action: { isMenuOpen.toggle() }) {
                    Image(systemName: "line.3.horizontal")
                        .resizable()
                        .frame(width: 28, height: 18)
                        .foregroundColor(Color.green)
                        .padding()
                }
                Spacer()
            }
            Spacer()
        }
        .padding()
        .zIndex(2) // 最前面にしてタップ領域を確保
    }

    
    private var currentLocationButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: centerOnUserLocation) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
        }
    }
    
    private var destinationSearchButton: some View {
        VStack {
            Spacer()
            HStack {
                Button(action: {
                    if route != nil {
                        // 目的地決定済みの場合はサジェスト表示をしない
                        isSuggesting = false
                    } else {
                        if isSuggesting {
                            isSuggesting = false  // 一度表示されたら再押下で非表示
                        } else {
                            suggestDestinations(category: selectedCategory == "すべて" ? nil : selectedCategory)
                        }
                    }
                }) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 38))
                        .foregroundColor(.white)
                        .padding()
                        .background(route != nil ? Color.gray : Color.blue)
                        .clipShape(Circle())
                }
                .padding(.leading, 16)
                .padding(.bottom, 16)
                Spacer()
            }
        }
    }

    
    private var searchBar: some View {
        VStack {
            HStack {
                TextField("目的地を入力", text: $searchQuery)
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 1)
                    .focused($isSearchFocused)
                    .onTapGesture {
                        // ✅ 検索窓タップでサジェストを閉じる
                        isSuggesting = false
                    }

                
                Button(action: {
                    searchAddress()
                    isSearchFocused = false
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .padding(10)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
            .padding()
            .padding(.top, 50)
            Spacer()
        }
    }
    
            
            private var suggestionOverlay: some View {
                Group {
                    if isSuggesting {
                        VStack {
                            Spacer()
                            VStack {
                                Picker("目的地の種類", selection: $selectedCategory) {
                                    Text("すべて").tag("すべて")
                                    Text("公園").tag("公園")
                                    Text("神社").tag("神社")
                                    Text("カフェ").tag("カフェ")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding()
                                
                                ScrollView {
                                    if suggestions.isEmpty {
                                        VStack {
                                            Spacer()
                                            ProgressView("検索中...")
                                                .padding()
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 250) // ✅ 固定高さ
                                    } else {
                                        ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                                            suggestionRow(for: suggestion)
                                        }
                                    }
                                }
                                .frame(maxHeight: 300) // ✅ 常に同じ高さで安定
                            }
                            .background(Color.white)
                            .cornerRadius(10)
                            .padding(.bottom, 200)
                        }
                    }
                }
            }



    
    @ViewBuilder
    private func suggestionRow(for suggestion: (item: MKMapItem, distance: Double, time: Double)) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(suggestion.item.name ?? "不明な場所")
                    .font(.headline)
                Text("距離: \(String(format: "%.1f", suggestion.distance / 1000)) km")
                Text("徒歩: \(Int(suggestion.time / 60)) 分")
            }
            Spacer()
            Button("tap") {
                fromSuggestion = true
                pendingDestination = suggestion.item.placemark.coordinate
                selectedSuggestion = (item: suggestion.item, distance: suggestion.distance, time: suggestion.time)
                
                isSuggesting = false
                withAnimation(.linear(duration: 0.2)) {
                    cameraPosition = .region(MKCoordinateRegion(center: suggestion.item.placemark.coordinate,
                                                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
                }
            }

        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 80)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 1)
        .padding(.horizontal)
    }
    
        private var detailSheet: some View {
            Group {
                if let detail = selectedSuggestion {
                    VStack {
                        Spacer()
                        VStack(spacing: 8) {

                            // ✅ 場所情報
                            Text(detail.item.name ?? "不明な場所")
                                .font(.headline)
                            Text("距離: \(String(format: "%.1f", detail.distance / 1000)) km")
                            Text("徒歩: \(Int(detail.time / 60)) 分")

                            // ✅ ボタン
                            Button("この場所を目的地にする") {
                                if let coord = pendingDestination {
                                    destination = coord
                                    calculateRoute()

                                    selectedSuggestion = nil
                                    pendingDestination = nil
                                    isSuggesting = false
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)

                            Button("閉じる") {
                                withAnimation {
                                    selectedSuggestion = nil
                                    pendingDestination = nil
                                    if fromSuggestion {
                                        isSuggesting = true
                                    } else {
                                        isSuggesting = false
                                    }
                                }
                            }

                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(radius: 2)
                        .frame(maxHeight: UIScreen.main.bounds.height / 2)
                    }
                }
            }
        }

    private var removeDestinationButton: some View {
        Group {
            if destination != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            destination = nil
                            route = nil
                            pendingDestination = nil
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("目的地を取り消す")
                            }
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }
        
        private var arrivalButton: some View {
            Group {
                if hasArrived {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                destination = nil
                                route = nil
                                pendingDestination = nil
                                hasArrived = false
                            }) {
                                Text("とうちゃく!")
                                    .font(.headline)
                                    .padding(.horizontal, 40)
                                    .padding(.vertical, 12)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            Spacer()
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
        }

}
