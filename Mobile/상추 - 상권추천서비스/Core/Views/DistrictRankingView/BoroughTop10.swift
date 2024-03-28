//
//  SwiftUIView.swift
//  상추 - 상권추천서비스
//
//  Created by 안상준 on 3/27/24.
//

//CommercialDistrictInfo

import SwiftUI
import Alamofire

struct CommercialDistrictCardView: View {
    var district: CommercialDistrictInfo
    var index: Int
    var topColors: [Color]
    var numberTop: [Color]
    var numberBottom: [Color]

    var body: some View {
        NavigationLink(destination: BDMapView(cameraLatitude: district.longitude, cameraLongitude: district.latitude, selectedCDCode: String(district.commercialDistrictCode) , selectedCDName: district.commercialDistrictName)) {
            ZStack {
                // 등수 관련 UI
                VStack{
                    Text("\(index + 1)").foregroundColor(index < 3 ? .white : Color(hex: "3D3D3D")).fontWeight(.bold).font(.system(size: 130))
                }
                .frame(width : 190 , height: 190)
                .background(
                    index < 3 ?
                    LinearGradient(colors: [numberTop[index % 3] ,numberBottom[index % 3]], startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [numberTop[3] ,numberBottom[3]], startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(60)
                .rotationEffect(.degrees(-28)).offset(x:120,y:-30)
                
                // 텍스트
                HStack{
                    VStack(alignment: .leading){
                        HStack{
                            Text("\(Int(district.commercialDistrictScore))점").font(.title).foregroundColor(index < 3 ? Color.white : Color.black).fontWeight(.bold)
                            Spacer()
                        }
                        HStack{
                            VStack(alignment: .leading){
                                Text("매출점수").font(.caption)
                                Text("상주인구점수").font(.caption)
                                Text("유동인구점수").font(.caption)
                                Text("다양성").font(.caption)
                            }.hidden()
                            VStack(alignment: .leading){
                                Text("\(Int(district.salesScore))").font(.caption)
                                Text("\(Int(district.residentPopulationScore))").font(.caption)
                                Text("\(Int(district.floatingPopulationScore))").font(.caption)
                                Text("\(Int(district.rdiScore))").font(.caption)
                            }.hidden()
                        }
                        VStack(alignment: .leading){
                            Text(district.commercialDistrictName).font(.title).fontWeight(.bold).foregroundColor(index < 3 ? .white.opacity(0.9) : Color(hex: "3D3D3D")).lineLimit(1)
                            Text("정보 보러가기 >").font(.caption2).foregroundColor(Color(hex: "767676"))
                        }
                    }.frame(maxWidth: UIScreen.main.bounds.width * 0.6)
                    Spacer()
                }
                
            }
        }.scrollTransition{ content, phase in
            content
                .opacity(phase.isIdentity ? 1.0 : 0.5)
        }
        .frame(width: UIScreen.main.bounds.width * 0.8, height : 180)
        .padding()
        .background( index < 3 ? topColors[index % 3] : Color.white)
        .foregroundColor(.white)
        .cornerRadius(10)
        // end of Navi
    }
}

struct BoroughTop10: View {
    // 상권배열
    @State var commercialDistricts: [CommercialDistrictInfo] = []
    // 자치구들 이름 배열
    let boroughsArray: [(key: String, value: Int)] = VariableMapping.boroughsToGuCode.sorted(by: { $0.key < $1.key })
    
    @State private var selectedGuCode: Int = VariableMapping.boroughsToGuCode["강남구"] ?? 11680
    
    func fetchTopCD(guCode: Int) {
        let urlString = "http://3.36.91.181:8084/api/commdist/gu/top?guCode=\(guCode)"
        AF.request(urlString).responseDecodable(of: [CommercialDistrictInfo].self) { response in
            switch response.result {
            case .success(let districts):
                // 결과 처리
                self.commercialDistricts = districts
            case .failure(let error):
                print("요청 실패: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(boroughsArray, id: \.self.key) { borough in
                        Button(action: {
                            // 버튼이 눌리면 선택된 자치구 업데이트
                            self.selectedGuCode = borough.value
                            // 선택된 자치구에 따라 상권 정보 업데이트
                            self.fetchTopCD(guCode: borough.value)
                        }) {
                            Text(borough.key).font(.system(size: 16)).fontWeight(.medium)
                        }
                        .frame(width: 78, height: 37)
                        .background(self.selectedGuCode == borough.value ? Color.sangchu : Color.white)
                        .foregroundColor(self.selectedGuCode == borough.value ? Color.white : Color.black)
                        .cornerRadius(5)
                    }
                }
            }
//            .scrollTargetLayout()
            .scrollIndicators(.hidden)
            
            // 자치구별 Top상권
            ScrollView (.horizontal) {
                HStack {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(Array(zip(commercialDistricts.indices, commercialDistricts)), id: \.0) { index, district in
                                CommercialDistrictCardView(district: district, index: index, topColors: AppColors.topColors, numberTop: AppColors.numberTop, numberBottom: AppColors.numberBottom)
                            }
                        }
                    }.scrollIndicators(.hidden)
                }
            }
            .scrollTargetLayout()
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
        }
        .onAppear {
            // 뷰가 나타날 때 디폴트 값(강남구)으로 데이터 불러오기
            self.fetchTopCD(guCode: self.selectedGuCode)
        }
        
    }
}
