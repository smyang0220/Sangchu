//
//  SalesChartView.swift
//  상추 - 상권추천서비스
//
//  Created by 안상준 on 3/25/24.
//

import SwiftUI
import Charts

enum SalesEndpoints: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    
    case 직전분기월평균및주중주말매출금액 = "recent" // /
    case 업종별매출비율 = "industryRatioGraph" // /graph/ratio-industry
    case 분기별월평균및주중주말매출금액 = "quarterlyGraph" // /graph/quarterly
    case 요일별매출건수및금액 = "dayGraph" // /graph/day
    case 시간대별매출건수및금액 = "timeGraph" // /graph/time
    case 연령대별매출건수및금액 = "ageGraph" // /graph/age

    var englishEndpoint: String {
        switch self {
            case .직전분기월평균및주중주말매출금액:
                return ""
            case .업종별매출비율:
                return "/graph/ratio-industry"
            case .분기별월평균및주중주말매출금액:
                return "/graph/quarterly"
            case .요일별매출건수및금액:
                return "/graph/day"
            case .시간대별매출건수및금액:
                return "/graph/time"
            case .연령대별매출건수및금액:
                return "/graph/age"
        }
    } // end of englishEndpoint
    
    var displayName: String {
            switch self {
                case .직전분기월평균및주중주말매출금액:
                    return "직전분기 월평균 및 주중/주말 매출 금액"
                case .업종별매출비율:
                    return "업종별 매출 비율"
                case .분기별월평균및주중주말매출금액:
                    return "분기별 월평균 및 주중/주말 매출 금액"
                case .요일별매출건수및금액:
                    return "요일별 매출 건수 및 금액"
                case .시간대별매출건수및금액:
                    return "시간대별 매출 건수 및 금액"
                case .연령대별매출건수및금액:
                    return "연령대별 매출 건수 및 금액"
            }
        } // end of displayName
}

//
struct IndustryRatioGraphView: View {
    var chartData: [SalesModel.IndustryRatioChartData]
    
    private var maxSalesCategory: String? {
        chartData.max(by: { $0.valueRatio < $1.valueRatio })?.label
    }

    var body: some View {
        VStack {
            HStack {
                Text("업종별 매출 비율")
                    .font(.title2).bold()
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: MainColors), startPoint: .top, endPoint: .bottom))
                Spacer() // HStack의 왼쪽 공간을 모두 차지하여, 오른쪽으로 밀어냅니다.
                
            }
            Chart(chartData, id: \.label) { dataItem in
                SectorMark(
                    angle: .value("매출 비율", dataItem.valueRatio),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.5
                )
                .cornerRadius(5)
                .opacity(dataItem.label == maxSalesCategory ? 1 : 0.5) // 가장 높은 매출 비율을 가진 업종을 강조
                .foregroundStyle(by: .value("업종", dataItem.label))
                .annotation(position: .overlay) {
                     Text("\(dataItem.valueRatio, specifier: "%.1f")%")
                        .font(.caption.bold())
                 }
            }
            .padding().padding(.bottom, 40)
        }
    }
}

//
struct QuarterlyGraphView: View {
    var chartData: [SalesModel.QuarterlyChartData]
    @State private var presentedData: [SalesModel.QuarterlyChartData] = []
    @State private var animate: Bool = false

    var body: some View {
        VStack {
            HStack {
                Text("분기별 월매출")
                    .font(.title2).bold()
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: MainColors), startPoint: .top, endPoint: .bottom))
                Spacer()
                Text("(단위 : 백만원)")
                    .font(.caption2)
                    .foregroundStyle(Color.customgray)
                    .padding(.trailing)
            }
            Chart(presentedData, id: \.id) { dataItem in
                BarMark(
                    x: .value("Quarter", dataItem.label),
                    y: .value("Sales", animate ? dataItem.valueWeekDay / 1000000 : 0 )
                )
                .foregroundStyle(.red)
                BarMark(
                    x: .value("Quarter", dataItem.label),
                    y: .value("Sales", animate ? dataItem.valueWeekend / 1000000 : 0 )
                )
                .foregroundStyle(.blue)
                .annotation(position: .automatic) {
                    Text("\((dataItem.valueWeekend + dataItem.valueWeekDay) / 1000000, specifier: "%.0f")")
                }
            }
            .padding().padding(.bottom, 40)
            .chartLegend(.visible)
            .onAppear {
                presentedData = chartData // 모든 데이터를 presentedData에 할당
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                        animate = true // 애니메이션 시작
                    }
                }
            }
            .onDisappear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.5)) {
                        animate = false // 애니메이션 시작
                    }
                }
            }
        }
    }
}

//
struct DayGraphView: View {
    var chartData: [SalesModel.CountAndAmountChartData]
    @State private var presentedData: [SalesModel.CountAndAmountChartData] = []
    @State private var animate: Bool = false
    @State private var selectedMetric: String = "매출 건수"

    var body: some View {
        VStack(spacing:5) {
            HStack {
                Text("요일별 매출")
                    .font(.title2).bold()
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: MainColors), startPoint: .top, endPoint: .bottom))
                Spacer()
                Text("(단위 : 만원)")
                    .font(.caption2)
                    .foregroundStyle(Color.customgray)
                    .padding(.trailing)
            }
            Picker("매출 데이터", selection: $selectedMetric) {
                Text("매출 건수").tag("매출 건수")
                Text("매출 금액").tag("매출 금액")
            }
            .pickerStyle(.segmented)
            .padding()
            
            Chart(chartData) { data in
                if selectedMetric == "매출 건수" {
                    BarMark(
                        x: .value("요일", data.label),
                        y: .value("매출 건수", animate ? data.count : 0)
                    )
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: MainColors), startPoint: .top, endPoint: .bottom))
                    .annotation(position: .top, alignment: .center) {
                        Text("\(data.count, specifier: "%.0f")건")
                            .font(.caption)
                    }
                } else {
                    BarMark(
                        x: .value("요일", data.label),
                        y: .value("매출 금액", animate ?  data.amount / 10000 : 0)
                    )
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: MainColors), startPoint: .top, endPoint: .bottom))
                    .annotation(position: .top, alignment: .center) {
                        Text("\(data.amount / 10000, specifier: "%.0f")")
                            .font(.caption)
                    }
                }
            }
            .padding().padding(.bottom, 40)
            .chartLegend(.visible)
            .onAppear {
                presentedData = chartData // 모든 데이터를 presentedData에 할당
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                        animate = true // 애니메이션 시작
                    }
                }
            }
            .onChange(of: selectedMetric) {
                animate = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                        animate = true // 애니메이션 시작
                    }
                }
            }
            .onDisappear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.interactiveSpring(response: 0.1, dampingFraction: 0.1, blendDuration: 0.1)) {
                        animate = false // 애니메이션 시작
                    }
                }
            }
        }
    }
    
}
//
struct TimeGraphView: View {
    var chartData: [SalesModel.CountAndAmountChartData]
    @State private var presentedData: [SalesModel.CountAndAmountChartData] = []
    @State private var animate: Bool = false
    @State private var selectedMetric: String = "매출 건수"

    var body: some View {
        VStack {
            HStack{
                Text("시간대별 월매출")
                    .font(.title2).bold()
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: MainColors), startPoint: .top, endPoint: .bottom))
                
                Spacer()
                Text("(단위 : 만원)")
                    .font(.caption2)
                    .foregroundColor(.customgray)
                    .padding(.trailing)
            }

            Picker("매출 데이터", selection: $selectedMetric) {
                Text("매출 건수").tag("매출 건수")
                Text("매출 금액").tag("매출 금액")
            }
            .pickerStyle(.segmented)
            .padding()

            Chart(chartData) { data in
                if selectedMetric == "매출 건수" {
                    BarMark(
                        x: .value("시간대", data.label),
                        y: .value("매출 건수", animate ? data.count : 0)
                    )
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: MainColors), startPoint: .top, endPoint: .bottom))
                    .annotation(position: .top, alignment: .center) {
                        Text("\(data.count, specifier: "%.0f")건")
                            .font(.caption)
                    }
                } else {
                    BarMark(
                        x: .value("시간대", data.label),
                        y: .value("매출 금액", animate ?  data.amount / 10000 : 0)
                    )
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: MainColors), startPoint: .top, endPoint: .bottom))
                    .annotation(position: .top, alignment: .center) {
                        Text("\(data.amount / 10000, specifier: "%.0f")")
                            .font(.caption)
                    }
                }
            }
            .chartLegend(.visible)
            .padding().padding(.bottom, 40)
            .onAppear {
                presentedData = chartData
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                        animate = true
                    }
                }
            }
            .onChange(of: selectedMetric) {
                animate = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                        animate = true
                    }
                }
            }
            .onDisappear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.interactiveSpring(response: 0.1, dampingFraction: 0.1, blendDuration: 0.1)) {
                        animate = false
                    }
                }
            }
        }
    }
}

// AgeGraphView
struct AgeGraphView: View {
    var chartData: [SalesModel.CountAndAmountChartData]
    @State private var presentedData: [SalesModel.CountAndAmountChartData] = []
    @State private var animate: Bool = false
    @State private var selectedMetric: String = "매출 건수"

    var body: some View {
        VStack {
            HStack{
                
                
                Text("연령대별 월매출")
                    .font(.title2).bold()
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: MainColors), startPoint: .top, endPoint: .bottom))
                Spacer()
                Text("(단위 : 만원)")
                    .font(.caption2)
                    .foregroundColor(.customgray)
                    .padding(.trailing)
            }

            Picker("매출 데이터", selection: $selectedMetric) {
                Text("매출 건수").tag("매출 건수")
                Text("매출 금액").tag("매출 금액")
            }
            .pickerStyle(.segmented)
            .padding()

            // 차트 표시
            Chart(chartData) { data in
                if selectedMetric == "매출 건수" {
                    BarMark(
                        x: .value("연령대", data.label),
                        y: .value("매출 건수", animate ? data.count : 0)
                    )
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: MainColors), startPoint: .top, endPoint: .bottom))
                    .annotation(position: .top, alignment: .center) {
                        Text("\(data.count, specifier: "%.0f")건")
                            .font(.caption)
                    }
                } else {
                    BarMark(
                        x: .value("연령대", data.label),
                        y: .value("매출 금액", animate ?  data.amount / 10000 : 0)
                    )
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: MainColors), startPoint: .top, endPoint: .bottom))
                    .annotation(position: .top, alignment: .center) {
                        Text("\(data.amount / 10000, specifier: "%.0f")")
                            .font(.caption)
                    }
                }
            }
            .chartLegend(.visible)
            .padding().padding(.bottom, 40)
            .onAppear {
                presentedData = chartData // 모든 데이터를 presentedData에 할당
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                        animate = true // 애니메이션 시작
                    }
                }
            }
            .onChange(of: selectedMetric) {
                animate = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)) {
                        animate = true // 애니메이션 시작
                    }
                }
            }
            .onDisappear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.interactiveSpring(response: 0.1, dampingFraction: 0.1, blendDuration: 0.1)) {
                        animate = false // 애니메이션 시작
                    }
                }
            }
        }
    }
}



struct SalesChartView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isLoading = true
    @State private var textDataSets : SalesModel.RecentSalesData?
    @State private var industryRatioChartDataSets : [SalesModel.IndustryRatioChartData] = []
    @State private var quarterlyChartDataSets : [SalesModel.QuarterlyChartData] = []
    @State private var dayChartDataSets: [SalesModel.CountAndAmountChartData] = []
    @State private var timeChartDataSets: [SalesModel.CountAndAmountChartData] = []
    @State private var ageChartDataSets: [SalesModel.CountAndAmountChartData] = []
    @State var cdCode: String = ""
    let recentQuarter = "2023년 3분기"
    
    
    var body: some View {
        ScrollView {
            VStack (alignment: .leading) {
                if isLoading {
                    Text("데이터 로딩 중")
                        .padding(.top)
                } else {
                    // 각종 차트 데이터들
                    TabView {
                        if isLoading {
                            Text("상권 데이터를 가져오는 중입니다.")
                        }
                        else {
                            Group {
                                // 분기별 유동인구 차트 표시
                                VStack {
                                    if !industryRatioChartDataSets.isEmpty {
                                        IndustryRatioGraphView(chartData: industryRatioChartDataSets)
//                                            .padding(.vertical, 200)
                                    }
                                }
                                VStack {
                                    if !quarterlyChartDataSets.isEmpty {
                                        QuarterlyGraphView(chartData: quarterlyChartDataSets)
                                    }
                                }
                                VStack {
                                    if !dayChartDataSets.isEmpty {
                                        DayGraphView(chartData: dayChartDataSets)
                                    }
                                }
                                VStack {
                                    if !timeChartDataSets.isEmpty {
                                        TimeGraphView(chartData: timeChartDataSets)
                                    }
                                }
                                VStack {
                                    if !ageChartDataSets.isEmpty {
                                        AgeGraphView(chartData: ageChartDataSets)
                                    }
                                }
                            }
                        }
                    } // end of TabView
                    .frame(height: 380)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .scrollIndicatorsFlash(onAppear: true)
                    .padding()
                    // 직전분기 매출 관련 VStack
                    
                    
                    VStack(spacing:10){
                        HStack{
                            Text("\(recentQuarter) 매출").font(.title2).fontWeight(.semibold)
                            Spacer()
                        }.frame(width: UIScreen.main.bounds.width * 0.9)
                        
                        VStack {
                            if let monthlySales = textDataSets?.monthlySales {
                                HStack{
                                    Spacer()
                                    Text("\(monthlySales)원").font(.title).fontWeight(.semibold).foregroundStyle(LinearGradient(colors: MainColors, startPoint: .leading, endPoint: .trailing))
                                    Spacer()
                                }.padding(15)
                            }
                        }.frame(width: UIScreen.main.bounds.width * 0.9,height: UIScreen.main.bounds.width * 0.2).background(colorScheme == .light ? Color(hex: "f4f5f7") : Color.black.opacity(0.1)) .cornerRadius(20).padding(.leading,20).padding(.trailing,20)
                    }.padding(.bottom,15)
                    
                    VStack(spacing:10){
                        HStack{
                            Text("주중 매출").font(.title2).fontWeight(.semibold)
                            Spacer()
                        }.frame(width: UIScreen.main.bounds.width * 0.9)
                        
                        VStack {
                            if let weekDaySales = textDataSets?.weekDaySales {
                                HStack{
                                    Spacer()
                                    Text("\(weekDaySales)원").font(.title).fontWeight(.semibold).foregroundStyle(LinearGradient(colors: MainColors, startPoint: .leading, endPoint: .trailing))
                                    Spacer()
                                }.padding(15)
                            }
                        }.frame(width: UIScreen.main.bounds.width * 0.9,height: UIScreen.main.bounds.width * 0.2).background(colorScheme == .light ? Color(hex: "f4f5f7") : Color.black.opacity(0.1)) .cornerRadius(20).padding(.leading,20).padding(.trailing,20)
                    }.padding(.bottom,15)
                    
                    VStack(spacing:10){
                        HStack{
                            Text("주말 매출").font(.title2).fontWeight(.semibold)
                            Spacer()
                        }.frame(width: UIScreen.main.bounds.width * 0.9)
                        
                        VStack {
                            if let weekendSales = textDataSets?.weekendSales {
                                HStack{
                                    Spacer()
                                    Text("\(weekendSales)원").font(.title).fontWeight(.semibold).foregroundStyle(LinearGradient(colors: MainColors, startPoint: .leading, endPoint: .trailing))
                                    Spacer()
                                }.padding(15)
                            }
                        }.frame(width: UIScreen.main.bounds.width * 0.9,height: UIScreen.main.bounds.width * 0.2).background(colorScheme == .light ? Color(hex: "f4f5f7") : Color.black.opacity(0.1)) .cornerRadius(20).padding(.leading,20).padding(.trailing,20)
                    }.padding(.bottom,15)
                    
                    
                    
//                    VStack (alignment: .leading, spacing: 10) {
//                        RoundedRectangle(cornerRadius: 20)
//                            .fill(.defaultbg)
//                            .frame(height: UIScreen.main.bounds.height * 0.2)
//                            .overlay(
//                                VStack(alignment: .leading, spacing: 5) {
//                                    Text("매출 요약")
//                                        .font(.largeTitle.bold())
//                                        .padding(.bottom, 10)
//                                    HStack {
//                                        Group {
//                                            Text(recentQuarter)
//                                                .foregroundColor(.defaultfont)
//                                                .font(.title2)
//                                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
//                                            if let monthlySales = textDataSets?.monthlySales {
//                                                Text("\(monthlySales)원")
//                                            } else {
//                                                Text("데이터 없음")
//                                            }
//                                        }
//                                    }
//                                    Divider()
//                                    HStack {
//                                        Group {
//                                            Text("주중")
//                                                .foregroundColor(.blue)
//                                                .font(.title2)
//                                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
//                                            if let weekDaySales = textDataSets?.weekDaySales {
//                                                Text("\(weekDaySales)원")
//                                            } else {
//                                                Text("데이터 없음")
//                                            }
//                                        }
//                                    }
//                                    Divider()
//                                    HStack {
//                                        Group {
//                                            Text("주말")
//                                                .foregroundColor(.red)
//                                                .font(.title2)
//                                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
//                                            if let weekendSales = textDataSets?.weekendSales {
//                                                Text("\(weekendSales)원")
//                                            } else {
//                                                Text("데이터 없음")
//                                            }
//                                        }
//                                    }
//                                }
//                        )
//                    }
//                    .padding(.horizontal)
                } // end of else
            } // end of outer VStack
            .onAppear() {
                loadSalesData()
            }
        } // end of ScrollView
    } // end of body view
    
    func loadSalesData() {
        isLoading = true
        let group = DispatchGroup()
        
        for (index, endpoint) in SalesEndpoints.allCases.enumerated() {
            group.enter() // 그룹에 작업 추가 시작

            let whereToGo = endpoint.id
            
            if whereToGo.contains("recent") {
                loadRecentData(endpoint: endpoint, index: index, group: group)
            }
            else if whereToGo.contains("industry") {
                loadindustryRatioData(endpoint: endpoint, index: index, group: group)
            }
            else if whereToGo.contains("quarterly") {
                 loadQuarterlyData(endpoint: endpoint, index: index, group: group)
            }
            else if whereToGo.contains("day") {
                 loadDayData(endpoint: endpoint, index: index, group: group)
            }
            else if whereToGo.contains("time") {
                 loadTimeData(endpoint: endpoint, index: index, group: group)
            }
            else if whereToGo.contains("age") {
                 loadAgeData(endpoint: endpoint, index: index, group: group)
            }
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
        
    } // end of loadSalesData
    
    //
    func loadRecentData(endpoint: SalesEndpoints, index: Int, group: DispatchGroup) {
        SalesNetworkManager.shared.fetch(endpoint: endpoint.englishEndpoint, commercialDistrictCode: cdCode) { result in
            DispatchQueue.main.async {
                defer { group.leave() }
                
                switch result {
                case .success(let data):
                    do {
                        let salesRecentApiResponse = try JSONDecoder().decode(SalesModel.RecentSalesData.self, from: data)
                        self.textDataSets = salesRecentApiResponse
                    } catch {
                        print("디코딩 오류: \(error)")
                    }
                case .failure(let error):
                    print("네트워크 오류: \(error.localizedDescription)")
                }
            }
        }
    }
    
    //
    func loadindustryRatioData(endpoint: SalesEndpoints, index: Int, group: DispatchGroup) {
        SalesNetworkManager.shared.fetch(endpoint: endpoint.englishEndpoint, commercialDistrictCode: cdCode) { result in
            DispatchQueue.main.async {
                defer { group.leave() }
                
                switch result {
                case .success(let data):
                    do {
                        let industryRatioApiResponse = try JSONDecoder().decode(SalesModel.RatioIndustry.self, from: data)
                        let chartData = zip(industryRatioApiResponse.graphJson.data.categories, industryRatioApiResponse.graphJson.data.series).map { SalesModel.IndustryRatioChartData(label: $0, valueRatio: $1) }
                        // 변환된 `ChartData` 배열을 `chartDataSets`에 저장
                        DispatchQueue.main.async {
                            self.industryRatioChartDataSets = chartData
                        }
                    } catch {
                        print("업종별 디코딩 오류: \(error)")
                    }
                case .failure(let error):
                    print("업종별 네트워크 오류: \(error.localizedDescription)")
                }
            }
        }
    }
    
    //
    func loadQuarterlyData(endpoint: SalesEndpoints, index: Int, group: DispatchGroup) {
        SalesNetworkManager.shared.fetch(endpoint: endpoint.englishEndpoint, commercialDistrictCode: cdCode) { result in
            DispatchQueue.main.async {
                defer { group.leave() }
                
                switch result {
                case .success(let data):
                    do {
                        let quarterlyApiResponse = try JSONDecoder().decode(SalesModel.QuarterlyApiResponse.self, from: data)
                        let chartData = quarterlyApiResponse.quarterlyGraph.data.series.map { series -> SalesModel.QuarterlyChartData in
                            // 주중 및 주말 매출 값을 Double로 변환, 실패 시 0.0
                            let weekDaySalesValue = Double(series.WeekDaySales) ?? 0.0
                            let weekendSalesValue = Double(series.WeekendSales) ?? 0.0
                            
                            // QuarterlyChartData 객체 생성
                            return SalesModel.QuarterlyChartData(label: series.YearQuarter, valueWeekDay: weekDaySalesValue, valueWeekend: weekendSalesValue)
                        }
                        self.quarterlyChartDataSets = chartData
                    } catch {
                        print("분기별 디코딩 오류: \(error)")
                    }
                case .failure(let error):
                    print("분기별 네트워크 오류: \(error.localizedDescription)")
                }
            }
        }
    }

    //
    func loadDayData(endpoint: SalesEndpoints, index: Int, group: DispatchGroup) {
        SalesNetworkManager.shared.fetch(endpoint: endpoint.englishEndpoint, commercialDistrictCode: cdCode) { result in
            DispatchQueue.main.async {
                defer { group.leave() }
                
                switch result {
                case .success(let data):
                    do {
                        let dayApiResponse = try JSONDecoder().decode(SalesModel.DayApiResponse.self, from: data)
                        var chartDataArray = [SalesModel.CountAndAmountChartData]()
                        for (i, category) in dayApiResponse.graphJson.data.categories.enumerated() {
                            let salesCount = dayApiResponse.graphJson.data.series.daySalesCount[i]
                            let salesAmount = dayApiResponse.graphJson.data.series.daySales[i]
                            let chartData = SalesModel.CountAndAmountChartData(label: category, count: Double(salesCount), amount: Double(salesAmount))
                            chartDataArray.append(chartData) // 배열에 추가합니다.
                        }
                        self.dayChartDataSets = chartDataArray
                    } catch {
                        print("요일별 디코딩 오류: \(error)")
                    }
                case .failure(let error):
                    print("요일별 네트워크 오류: \(error.localizedDescription)")
                }
            }
        }
    }

    //
    func loadTimeData(endpoint: SalesEndpoints, index: Int, group: DispatchGroup) {
        SalesNetworkManager.shared.fetch(endpoint: endpoint.englishEndpoint, commercialDistrictCode: cdCode) { result in
            DispatchQueue.main.async {
                defer { group.leave() }

                switch result {
                case .success(let data):
                    do {
                        let timeApiResponse = try JSONDecoder().decode(SalesModel.TimeApiResponse.self, from: data)
                        var chartDataArray: [SalesModel.CountAndAmountChartData] = []
                        for (i, category) in timeApiResponse.graphJson.data.categories.enumerated() {
                            let salesCount = Double(timeApiResponse.graphJson.data.series.timeSalesCount[i])
                            let salesAmount = Double(timeApiResponse.graphJson.data.series.timeSales[i])
                            let chartData = SalesModel.CountAndAmountChartData(label: category, count: salesCount, amount: salesAmount)
                            chartDataArray.append(chartData)
                        }
                        self.timeChartDataSets = chartDataArray
                    } catch {
                        print("시간대별 디코딩 오류: \(error)")
                    }
                case .failure(let error):
                    print("시간대별 네트워크 오류: \(error.localizedDescription)")
                }
            }
        }
    }

    //
    func loadAgeData(endpoint: SalesEndpoints, index: Int, group: DispatchGroup) {
        SalesNetworkManager.shared.fetch(endpoint: endpoint.englishEndpoint, commercialDistrictCode: cdCode) { result in
            DispatchQueue.main.async {
                defer { group.leave() }

                switch result {
                case .success(let data):
                    do {
                        let ageApiResponse = try JSONDecoder().decode(SalesModel.AgeApiResponse.self, from: data)
                        var chartDataArray: [SalesModel.CountAndAmountChartData] = []
                        for (i, category) in ageApiResponse.graphJson.data.categories.enumerated() {
                            let salesCount = Double(ageApiResponse.graphJson.data.series.ageSalesCount[i])
                            let salesAmount = Double(ageApiResponse.graphJson.data.series.ageSales[i])
                            let chartData = SalesModel.CountAndAmountChartData(label: category, count: salesCount, amount: salesAmount)
                            chartDataArray.append(chartData)
                        }
                        self.ageChartDataSets = chartDataArray
                    } catch {
                        print("연령대별 디코딩 오류: \(error)")
                    }
                case .failure(let error):
                    print("연령대별 네트워크 오류: \(error.localizedDescription)")
                }
            }
        }
    }

}
