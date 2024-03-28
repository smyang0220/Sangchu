import SwiftUI
import Alamofire

struct FilteredDistrictsData : Codable {
    var totalScoreSorted: [DistrictData] = []
    var salesSorted: [DistrictData] = []
    var footTrafficSorted: [DistrictData] = []
    var residentialPopulationSorted: [DistrictData] = []
    var businessDiversitySorted: [DistrictData] = []
}

struct FilteredValue : Codable {
    var value: Int // 실제 값 // ex) 매출 1억 // 단 총점순인 경우 서울시 전체에서의 점수
    var score: Double // 점수 // ex) 매출별 점수 98
}

// 상권 정보
struct DistrictData: Codable {
    var cdCode: Int // 상권 코드
    var name: String // 상권 이름
    var totalScore: FilteredValue // 총점
    var sales: FilteredValue // 매출액 및 점수
    var footTraffic: FilteredValue // 유동인구 및 점수
    var residentialPopulation: FilteredValue // 상주인구 및 점수
    var businessDiversity: FilteredValue // 업종다양성 및 점수
}

struct CommercialDistrictInfo: Codable {
    var commercialDistrictCode: Int
    var commercialDistrictName: String
    var latitude: Double
    var longitude: Double
    var guCode: Int
    var guName: String
    var dongCode: Int
    var dongName: String
    var areaSize: Int
    var commercialDistrictScore: Double
    var salesScore: Double
    var residentPopulationScore: Double
    var floatingPopulationScore: Double
    var rdiScore: Double
}

//// 위도, 경도 표시
//struct DistrictDetailView: View {
//    var latitude: Double
//    var longitude: Double
//    
//    var body: some View {
//        VStack {
//            Text("위도: \(latitude)")
//            Text("경도: \(longitude)")
//        }
//    }
//}

// ScrollView 내부의 카드 하나
struct CardView: View {
    var districtData: DistrictData // 상권 정보
    var index: Int // 해당 카드의 인덱스
    var selectedFilter: String // 필터링 기준
    
    @State private var districtInfo: CommercialDistrictInfo? = nil
    
    func fetchCommercialDistrictInfo(for cdCode: String) async throws {
        let urlString = "http://3.36.91.181:8084/api/commdist/commercial?commercialDistrictCode=\(cdCode)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let districtInfo = try JSONDecoder().decode(CommercialDistrictInfo.self, from: data)
        
        self.districtInfo = districtInfo
    }
    
    // 필터링에 따라 카드에 보여질 내용 만드는 함수
    func formattedSelectedValue() -> String {
        switch selectedFilter {
        case "종합순":
                return "서울시 내 상권 중 \(districtData.totalScore.value)등"
        case "매출순":
                return "\(districtData.sales.value)원"
        case "유동인구순":
            return "\(districtData.footTraffic.value)명"
        case "상주인구순":
            return "\(districtData.residentialPopulation.value)명"
        case "업종다양성순":
            return "\(districtData.businessDiversity.value) 업종"
        default:
            return "정보 없음"
        }
    }
    
    func selectedScore() -> Double {
           switch selectedFilter {
           case "종합순":
                   return districtData.totalScore.score
           case "매출순":
               return districtData.sales.score
           case "유동인구순":
               return districtData.footTraffic.score
           case "상주인구순":
               return districtData.residentialPopulation.score
           case "업종다양성순":
               return districtData.businessDiversity.score
           default:
               return 0 // 기본값 혹은 해당하는 필터링이 없을 경우
           }
       }

    var body: some View {
            VStack {
                // districtInfo 상태 변수가 nil이 아닐 경우에만 NavigationLink를 표시합니다.
                if let districtInfo = districtInfo {
                    // districtInfo가 존재한다면, NavigationLink를 통해 상세 정보 뷰(BDMapView)로 이동합니다.
                    // 이동할 때, districtInfo의 정보(위도, 경도, 상권 코드, 상권 이름)를 BDMapView에 전달합니다.
                    NavigationLink(destination: BDMapView(cameraLatitude: districtInfo.longitude, cameraLongitude: districtInfo.latitude, selectedCDCode: String(districtInfo.commercialDistrictCode), selectedCDName: districtInfo.commercialDistrictName)) {
                        ZStack {
                            // 등수, 상권 이름 등을 표시하는 UI 구성
                            VStack {
                                Text("\(index + 1)")
                                    .foregroundColor(index < 3 ? .white : Color(hex: "3D3D3D"))
                                    .fontWeight(.bold)
                                    .font(.system(size: 130))
                            }
                            .frame(width: 190, height: 190)
                            .background(
                                LinearGradient(colors: [AppColors.numberTop[index % 3], AppColors.numberBottom[index % 3]], startPoint: .top, endPoint: .bottom)
                            )
                            .cornerRadius(60)
                            .rotationEffect(.degrees(-28))
                            .offset(x: 120, y: -30)
                            
                            // 상권 이름 및 추가 정보를 표시하는 영역
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(districtInfo.commercialDistrictName)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(index < 3 ? .white : Color(hex: "3D3D3D"))
//                                        .opacity(0.7)
                                        .lineLimit(1)
                                    // 여기
                                    Text(formattedSelectedValue())
                                        .font(.headline)
                                        .foregroundColor(index < 3 ? .white : Color(hex: "3D3D3D"))
                                        .padding(.top, 2)

                                    Text("\(String(format: "%.0f", selectedScore())) 점")
                                        .font(.largeTitle)
                                        .foregroundColor(index < 3 ? .white : Color(hex: "3D3D3D"))
                                    Text("정보 보러가기 >").font(.caption2).foregroundColor(Color(hex: "767676"))
                                }
                                .frame(maxWidth: UIScreen.main.bounds.width * 0.6)
                                Spacer()
                            }
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.8, height: 180)
                    .padding()
                    .background(index < 3 ? AppColors.topColors[index % 3] : Color.white)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                } else {
                    // districtInfo가 nil일 경우, 로딩 표시
                    Spacer().frame(height: 120)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .sangchu))
                        .scaleEffect(3)
                }
            }
            .onAppear {
                Task {
                    do {
                        try await fetchCommercialDistrictInfo(for: String(districtData.cdCode))
                    } catch {
                        print("Error fetching district info: \(error)")
                    }
                }
            }
        }
} // end of CardView

struct DistrictRankingView: View {
    @State private var isLoading = false
    @State private var hasFetchedData = false // 데이터를 이미 가져왔는지 여부 // 무한 렌더링 방지
    @State private var filteredDistrictsData = FilteredDistrictsData(totalScoreSorted: [], salesSorted: [], footTrafficSorted: [], residentialPopulationSorted: [], businessDiversitySorted: [])
    @State private var selectedPage = 0
    @State private var selectedFilter = "종합순"
    
    var borough : String
    var category : String
    let filters = ["종합순", "매출순", "유동인구순", "상주인구순", "업종다양성순", "점포밀도순"]
    
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    @State private var startAnimation : Bool = false
    let universalSize = UIScreen.main.bounds
    
    
    func getSinWave(interval : CGFloat, amplitude : CGFloat = 100,baseline:CGFloat = UIScreen.main.bounds.height / 2) ->
    Path{
        Path { path in
            path.move(to: CGPoint(x:0, y:baseline))
            path.addCurve(to: CGPoint(x : 1 * interval, y : baseline),
                          control1: CGPoint(x:interval * (0.3),y: amplitude + baseline),
                          control2: CGPoint(x:interval * (0.7),y: -amplitude + baseline)
            )
            path.addCurve(to: CGPoint(x : 2 * interval, y : baseline),
                          control1: CGPoint(x:interval * (1.3),y: amplitude + baseline),
                          control2: CGPoint(x:interval * (1.7),y: -amplitude + baseline)
            )
            path.addLine(to: CGPoint(x: 2 * interval, y: universalSize.height))
            path.addLine(to: CGPoint(x: 0 , y: universalSize.height))
        }
    }
    
    private var currentFilteredData: [DistrictData] {
        switch selectedFilter {
        case "종합순":
            return filteredDistrictsData.totalScoreSorted
        case "매출순":
            return filteredDistrictsData.salesSorted
        case "유동인구순":
            return filteredDistrictsData.footTrafficSorted
        case "상주인구순":
            return filteredDistrictsData.residentialPopulationSorted
        case "업종다양성순":
            return filteredDistrictsData.businessDiversitySorted
        default:
            return []
        }
    }
    
    var body: some View {
        ZStack{
            getSinWave(interval: universalSize.width * 1.5 , amplitude: 150, baseline: 65 + universalSize.height / 2)
            //.stroke(lineWidth: 2) // 선만
                .foregroundColor(Color.red.opacity(0.3))
                .offset(x: startAnimation ? -1 * (universalSize.width * 1.5) : 0)
                .animation(Animation.linear(duration: 5).repeatForever(autoreverses: false))
            
            getSinWave(interval: universalSize.width , amplitude: 200, baseline: 70 + universalSize.height / 2)
                .foregroundColor(Color("sangchu").opacity(0.3))
                .offset(x: startAnimation ? -1 * (universalSize.width) : 0)
                .animation(Animation.linear(duration: 11).repeatForever(autoreverses: false))
            
            getSinWave(interval: universalSize.width * 3 , amplitude: 200, baseline: 95 + universalSize.height / 2)
                .foregroundColor(Color.black.opacity(0.2))
                .offset(x: startAnimation ? -1 * (universalSize.width * 3) : 0)
                .animation(Animation.linear(duration: 4).repeatForever(autoreverses: false))
            
            getSinWave(interval: universalSize.width * 1.2 , amplitude: 50, baseline: 75 + universalSize.height / 2)
                .foregroundColor(Color.init(red:0.6, green:0.9, blue : 1).opacity(0.4))
                .offset(x: startAnimation ? -1 * (universalSize.width * 1.2) : 0)
                .animation(Animation.linear(duration: 4).repeatForever(autoreverses: false))
            
            
            VStack {
                Spacer().frame(height: 40)
                // 필터링 버튼 추가
                
//                VStack{
//                    if isLoading{
//                        Text("분석중").font(.title).fontWeight(.semibold).padding(.top , 40)
//                    }else{
//                        Text("분석 결과").font(.title).fontWeight(.semibold).padding(.top , 40)
//                    }
//                }
               
                
                HStack{
                    Menu {
                        ForEach(filters, id: \.self) { filter in
                            Button(filter) {
                                selectedFilter = filter
                            }
                        }
                    }
                label: {
                    HStack {
                        Text(selectedFilter)
                        Image(systemName: "chevron.down")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                }
                    Spacer()
                }
                
                if isLoading {
                    VStack {
                        Spacer().frame(height: 90)
                        Text("분석중").font(.title).fontWeight(.semibold)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .sangchu))
                            .scaleEffect(5)
                    }
                }
                else {
                    Text("분석 결과").font(.title).fontWeight(.semibold)
                    TabView {
                        ForEach(currentFilteredData.indices, id: \.self) { index in
                            CardView(districtData: currentFilteredData[index], index: index, selectedFilter: selectedFilter)
                                .frame(width: UIScreen.main.bounds.width * 0.8)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // 원형 인디케이터를 항상 표시합니다.
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.35) // TabView의 크기를 지정합니다.
                    .onAppear {
                        if !hasFetchedData {
                            Task {
                                isLoading = true
                                do {
                                    // API 요청을 통해 filteredDistrictsData를 초기화
                                    let fetchedData = try await API.fetchFilteredDistrictsData(borough: borough, category: category)
                                    self.filteredDistrictsData = fetchedData
                                } catch {
                                    print("데이터를 가져오는 데 실패했습니다.")
                                }
                                isLoading = false
                                hasFetchedData = true
                            }
                        }
                    }
                }
                Spacer()
            } // end of VStack
            
        }.navigationTitle("\(borough)_\(category)")
            .ignoresSafeArea(.all)
            .onAppear{
                self.startAnimation = true
            }
            .background(Color(hex: "F4F5F7"))
        
    } // end of body view
} // end of DistrictRankingView

struct API {
    static func fetchFilteredDistrictsData(borough: String, category: String) async throws -> FilteredDistrictsData {
        guard let guCode = VariableMapping.boroughsToGuCode[borough],
              let serviceCode = VariableMapping.categoryToServiceCode[category] else {
            print("여기서 막힘!")
            throw URLError(.badURL)
        }

        print("guCode = \(guCode)")
        print("category = \(category)")
        
        let url = "http://3.36.91.181:8084/api/commdist/district-rank?guCode=\(guCode)&serviceCode=\(serviceCode)"
        do {
            let response: DataResponse<[DistrictData], AFError> = try await AF.request(url).serializingDecodable([DistrictData].self).response
            switch response.result {
            case .success(let districtDatas):
                var tmpFilteredData = FilteredDistrictsData()
                tmpFilteredData.totalScoreSorted = districtDatas.sorted(by: { $0.totalScore.score > $1.totalScore.score })
                tmpFilteredData.salesSorted = districtDatas.sorted(by: { $0.sales.score > $1.sales.score })
                tmpFilteredData.footTrafficSorted = districtDatas.sorted(by: { $0.footTraffic.score > $1.footTraffic.score })
                tmpFilteredData.residentialPopulationSorted = districtDatas.sorted(by: { $0.residentialPopulation.score > $1.residentialPopulation.score })
                tmpFilteredData.businessDiversitySorted = districtDatas.sorted(by: { $0.businessDiversity.score > $1.businessDiversity.score })
                return tmpFilteredData
            case .failure(let error):
                print("Request error: \(error)")
                throw error
            }
        } catch {
            throw error
        }
    }
}
