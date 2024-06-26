package com.sc.sangchu.postgresql.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.sc.sangchu.dto.sales.*;
import com.sc.sangchu.postgresql.entity.CommEstimatedSalesEntity;
import com.sc.sangchu.postgresql.repository.CommEstimatedSalesRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@Slf4j
public class CommSalesGraphService {

    private final CommEstimatedSalesRepository commEstimatedSalesRepository;
    private final RedisTemplate<String, Object> redisTemplate;
    private final ObjectMapper objectMapper;
    private final Integer YEAR = LocalDate.now().getYear();

    @Autowired
    public CommSalesGraphService(CommEstimatedSalesRepository commEstimatedSalesRepository,
        RedisTemplate<String, Object> redisTemplate, ObjectMapper objectMapper) {
        this.commEstimatedSalesRepository = commEstimatedSalesRepository;
        this.redisTemplate = redisTemplate;
        this.objectMapper = objectMapper;
    }

    //특정 상권 코드에 해당하는 월 매출, 주중/주말 매출 조회
    public CommSalesDto getSalesData(Long commCode) {
        try {
            //매출 계산 로직 좀 더 고민해 봐야함.
            //월 매출, 주중/주말 매출 계산
            List<CommEstimatedSalesEntity> salesList = commEstimatedSalesRepository.findByYearCodeAndCommercialDistrictCodeAndMajorCategoryName(
                YEAR - 1, commCode, "외식업");

            return calcSalesAvg(salesList);
        } catch (Exception e) {
            log.error("getSalesData error", e);
        }
        return null;
    }

    public CommQuarterlyGraphJsonDTO getQuarterlyGraphData(Long commCode) {
        String cacheKey = "salesGraph:quarterlyGraph:" + commCode;

        try {
            // Redis에서 캐시된 데이터 조회
            Object dataFromRedis = redisTemplate.opsForValue().get(cacheKey);

            if (dataFromRedis != null) {
                ObjectMapper mapper = new ObjectMapper();
                JsonNode cachedData = mapper.convertValue(dataFromRedis, JsonNode.class);
                return CommQuarterlyGraphJsonDTO.builder()
                    .quarterlyGraph(cachedData)
                    .build();
            }

            //특정 상권 코드의 22~23년도 주중/주말 매출 조회
            List<CommQuarterlyGraphDTO> salesList = commEstimatedSalesRepository.findByQuarterlyData(
                commCode,
                "외식업", new int[]{YEAR - 2, YEAR - 1});

            ObjectNode chartData = objectMapper.createObjectNode();
            chartData.put("chartType", "stackbar");
            chartData.put("year", (YEAR - 1) + "~" + (YEAR - 2));

            ObjectNode data = objectMapper.createObjectNode();
            ArrayNode categories = objectMapper.createArrayNode();
            ArrayNode series = objectMapper.createArrayNode();

            for (CommQuarterlyGraphDTO dto : salesList) {
                String yearQuarter = dto.getYear().toString() + "-" + dto.getQuarter().toString();
                categories.add(yearQuarter);
                ObjectNode seriesData = objectMapper.createObjectNode();
                seriesData.put("YearQuarter", yearQuarter);
                seriesData.put("WeekDaySales", String.format("%.0f", dto.getWeekDaySales()));
                seriesData.put("WeekendSales", String.format("%.0f", dto.getWeekendSales()));
                series.add(seriesData);
            }

            data.set("categories", categories);
            data.set("series", series);
            chartData.set("data", data);

            // 차트 데이터 캐시
            redisTemplate.opsForValue().set(cacheKey, chartData);

            return CommQuarterlyGraphJsonDTO.builder()
                .quarterlyGraph(chartData)
                .build();
        } catch (Exception e) {
            log.error("getSalesData error", e);
        }
        return null;
    }

    public CommSalesGraphJsonDTO getDayGraphData(Long commCode) {
        String cacheKey = "salesGraph:dayGraph:" + commCode;

        try {
            // Redis에서 캐시된 데이터 조회
            Object dataFromRedis = redisTemplate.opsForValue().get(cacheKey);

            if (dataFromRedis != null) {
                ObjectMapper mapper = new ObjectMapper();
                JsonNode cachedData = mapper.convertValue(dataFromRedis, JsonNode.class);
                return CommSalesGraphJsonDTO.builder()
                    .graphJson(cachedData)
                    .build();
            }

            List<CommEstimatedSalesEntity> salesList = commEstimatedSalesRepository.findByYearCodeAndCommercialDistrictCodeAndMajorCategoryName(
                YEAR - 1, commCode, "외식업");
            String[] category = {"월", "화", "수", "목", "금", "토", "일"};
            String type = "day";
            if (salesList.isEmpty()) {
                return null;
            }
            return setSalesGraphJsonDto(cacheKey, calcDailySalesSum(salesList), category, type);
        } catch (Exception e) {
            log.error("getDayGraphData error", e);
        }
        return null;
    }

    public CommSalesGraphJsonDTO getTimeGraphData(Long commCode) {
        String cacheKey = "salesGraph:timeGraph:" + commCode;

        try {
            // Redis에서 캐시된 데이터 조회
            Object dataFromRedis = redisTemplate.opsForValue().get(cacheKey);

            if (dataFromRedis != null) {
                ObjectMapper mapper = new ObjectMapper();
                JsonNode cachedData = mapper.convertValue(dataFromRedis, JsonNode.class);
                return CommSalesGraphJsonDTO.builder()
                    .graphJson(cachedData)
                    .build();
            }

            List<CommEstimatedSalesEntity> salesList = commEstimatedSalesRepository.findByYearCodeAndCommercialDistrictCodeAndMajorCategoryName(
                YEAR - 1, commCode, "외식업");
            String[] category = {"00~06시", "06~11시", "11~14시", "14~17시", "17~21시", "21~24시"};
            String type = "time";
            if (salesList.isEmpty()) {
                return null;
            }
            return setSalesGraphJsonDto(cacheKey, calcTimeSalesSum(salesList), category, type);
        } catch (Exception e) {
            log.error("getDayGraphData error", e);
        }
        return null;
    }

    public CommSalesGraphJsonDTO getAgeGraphData(Long commCode) {
        String cacheKey = "salesGraph:ageGraph:" + commCode;

        try {
            // Redis에서 캐시된 데이터 조회
            Object dataFromRedis = redisTemplate.opsForValue().get(cacheKey);

            if (dataFromRedis != null) {
                ObjectMapper mapper = new ObjectMapper();
                JsonNode cachedData = mapper.convertValue(dataFromRedis, JsonNode.class);
                return CommSalesGraphJsonDTO.builder()
                    .graphJson(cachedData)
                    .build();
            }

            List<CommEstimatedSalesEntity> salesList = commEstimatedSalesRepository.findByYearCodeAndCommercialDistrictCodeAndMajorCategoryName(
                YEAR - 1, commCode, "외식업");

            String[] category = {"10대", "20대", "30대", "40대", "50대", "60대이상"};
            String type = "age";

            if (salesList.isEmpty()) {
                return null;
            }
            return setSalesGraphJsonDto(cacheKey, calcAgeSalesSum(salesList), category, type);
        } catch (Exception e) {
            log.error("getAgeGraphData error", e);
        }
        return null;
    }

    public CommSalesRatioByServiceJsonDTO getSalesRatioByService(Long commCode) {
        String cacheKey = "SalesGraph:salesRatioGraph:" + commCode;

        try {
            // Redis에서 캐시된 데이터 조회
            Object dataFromRedis = redisTemplate.opsForValue().get(cacheKey);

            if (dataFromRedis != null) {
                ObjectMapper mapper = new ObjectMapper();
                JsonNode cachedData = mapper.convertValue(dataFromRedis, JsonNode.class);
                return CommSalesRatioByServiceJsonDTO.builder()
                    .graphJson(cachedData)
                    .build();
            }

            List<CommEstimatedSalesEntity> salesList = commEstimatedSalesRepository.findByYearCodeAndCommercialDistrictCodeAndMajorCategoryName(
                YEAR - 1, commCode, "외식업");

            ObjectNode chartData = objectMapper.createObjectNode();
            chartData.put("chartType", "donut");
            chartData.put("year", YEAR - 1);
            chartData.put("commDistrictName",
                salesList.isEmpty() ? "" : salesList.get(0).getCommercialDistrictName());

            ObjectNode data = objectMapper.createObjectNode();
            ArrayNode categories = objectMapper.createArrayNode();
            ArrayNode series = objectMapper.createArrayNode();

            if (!salesList.isEmpty()) {
                Map<String, Double> dto = setSalesRatioByService(salesList);
                for (Map.Entry<String, Double> entry : dto.entrySet()) {
                    categories.add(entry.getKey());
                    series.add(Math.round(entry.getValue() * 10.0) / 10.0);
                }
            }

            data.set("categories", categories);
            data.set("series", series);
            chartData.set("data", data);

            // 차트 데이터 캐시
            redisTemplate.opsForValue().set(cacheKey, chartData);

            return CommSalesRatioByServiceJsonDTO.builder()
                .graphJson(chartData)
                .build();
        } catch (Exception e) {
            log.error("getSalesRatioByService error", e);
        }
        return null;
    }

    public CommSalesDto calcSalesAvg(List<CommEstimatedSalesEntity> salesList) {
        if (salesList == null) {
            return null;
        }
        double monthlySales = 0.0;
        double weekdaySales = 0.0;
        double weekendSales = 0.0;

        for (CommEstimatedSalesEntity entity : salesList) {
            monthlySales += entity.getMonthlySales();
            weekdaySales += entity.getWeekDaysSales();
            weekendSales += entity.getWeekendSales();
        }

        return CommSalesDto.builder()
            .monthlySales(Math.round(monthlySales / salesList.size()))
            .weekDaySales(Math.round(weekdaySales / salesList.size()))
            .weekendSales(Math.round(weekendSales / salesList.size()))
            .build();
    }

    public CommSalesGraphDTO calcDailySalesSum(List<CommEstimatedSalesEntity> salesList) {

        Long[] dailyCnt = new Long[7];
        Double[] dailySales = new Double[7];
        Arrays.fill(dailyCnt, 0L);
        Arrays.fill(dailySales, 0D);

        for (CommEstimatedSalesEntity entity : salesList) {
            if (entity != null) {
                dailyCnt[0] += (entity.getMonSalesCount() != null ? entity.getMonSalesCount() : 0L);
                dailyCnt[1] += (entity.getTueSalesCount() != null ? entity.getTueSalesCount() : 0L);
                dailyCnt[2] += (entity.getWedSalesCount() != null ? entity.getWedSalesCount() : 0L);
                dailyCnt[3] += (entity.getThuSalesCount() != null ? entity.getThuSalesCount() : 0L);
                dailyCnt[4] += (entity.getFriSalesCount() != null ? entity.getFriSalesCount() : 0L);
                dailyCnt[5] += (entity.getSatSalesCount() != null ? entity.getSatSalesCount() : 0L);
                dailyCnt[6] += (entity.getSunSalesCount() != null ? entity.getSunSalesCount() : 0L);
                dailySales[0] += (entity.getMonSales() != null ? entity.getMonSales() : 0L);
                dailySales[1] += (entity.getTueSales() != null ? entity.getTueSales() : 0L);
                dailySales[2] += (entity.getWedSales() != null ? entity.getWedSales() : 0L);
                dailySales[3] += (entity.getThuSales() != null ? entity.getThuSales() : 0L);
                dailySales[4] += (entity.getFriSales() != null ? entity.getFriSales() : 0L);
                dailySales[5] += (entity.getSatSales() != null ? entity.getSatSales() : 0L);
                dailySales[6] += (entity.getSunSales() != null ? entity.getSunSales() : 0L);

            }
        }
        for(int i = 0; i < dailySales.length; i++){
            dailySales[i] /= 30;
            dailyCnt[i] /= 30;
        }

        return CommSalesGraphDTO.builder()
            .year(salesList.get(0).getYearCode())
            .commDistrictName(salesList.get(0).getCommercialDistrictName())
            .salesCount(dailyCnt)
            .sales(dailySales)
            .build();
    }

    public CommSalesGraphDTO calcTimeSalesSum(List<CommEstimatedSalesEntity> salesList) {

        Long[] timeCnt = new Long[6];
        Double[] timeSales = new Double[6];
        Arrays.fill(timeCnt, 0L);
        Arrays.fill(timeSales, 0D);

        for (CommEstimatedSalesEntity entity : salesList) {
            if (entity != null) {
                timeCnt[0] += (entity.getTime00To06SalesCount() != null
                    ? entity.getTime00To06SalesCount() : 0L);
                timeCnt[1] += (entity.getTime06To11SalesCount() != null
                    ? entity.getTime06To11SalesCount() : 0L);
                timeCnt[2] += (entity.getTime11To14SalesCount() != null
                    ? entity.getTime11To14SalesCount() : 0L);
                timeCnt[3] += (entity.getTime14To17SalesCount() != null
                    ? entity.getTime14To17SalesCount() : 0L);
                timeCnt[4] += (entity.getTime17To21SalesCount() != null
                    ? entity.getTime17To21SalesCount() : 0L);
                timeCnt[5] += (entity.getTime21To24SalesCount() != null
                    ? entity.getTime21To24SalesCount() : 0L);
                timeSales[0] += (entity.getTime00To06Sales() != null ? entity.getTime00To06Sales()
                    : 0L);
                timeSales[1] += (entity.getTime06To11Sales() != null ? entity.getTime06To11Sales()
                    : 0L);
                timeSales[2] += (entity.getTime11To14Sales() != null ? entity.getTime11To14Sales()
                    : 0L);
                timeSales[3] += (entity.getTime14To17Sales() != null ? entity.getTime14To17Sales()
                    : 0L);
                timeSales[4] += (entity.getTime17To21Sales() != null ? entity.getTime17To21Sales()
                    : 0L);
                timeSales[5] += (entity.getTime21To24Sales() != null ? entity.getTime21To24Sales()
                    : 0L);
            }
        }

        for(int i = 0; i < timeSales.length; i++){
            timeSales[i] /= 30;
            timeCnt[i] /= 30;
        }

        return CommSalesGraphDTO.builder()
            .year(salesList.get(0).getYearCode())
            .commDistrictName(salesList.get(0).getCommercialDistrictName())
            .salesCount(timeCnt)
            .sales(timeSales)
            .build();
    }

    public CommSalesGraphDTO calcAgeSalesSum(List<CommEstimatedSalesEntity> salesList) {

        Long[] ageCnt = new Long[6];
        Double[] ageSales = new Double[6];
        Arrays.fill(ageCnt, 0L);
        Arrays.fill(ageSales, 0D);

        for (CommEstimatedSalesEntity entity : salesList) {
            if (entity != null) {
                ageCnt[0] += (entity.getAge10SalesCount() != null ? entity.getAge10SalesCount()
                    : 0L);
                ageCnt[1] += (entity.getAge20SalesCount() != null ? entity.getAge20SalesCount()
                    : 0L);
                ageCnt[2] += (entity.getAge30SalesCount() != null ? entity.getAge30SalesCount()
                    : 0L);
                ageCnt[3] += (entity.getAge40SalesCount() != null ? entity.getAge40SalesCount()
                    : 0L);
                ageCnt[4] += (entity.getAge50SalesCount() != null ? entity.getAge50SalesCount()
                    : 0L);
                ageCnt[5] += (entity.getAgeOver60SalesCount() != null
                    ? entity.getAgeOver60SalesCount() : 0L);
                ageSales[0] += (entity.getAge10Sales() != null ? entity.getAge10Sales() : 0L);
                ageSales[1] += (entity.getAge20Sales() != null ? entity.getAge20Sales() : 0L);
                ageSales[2] += (entity.getAge30Sales() != null ? entity.getAge30Sales() : 0L);
                ageSales[3] += (entity.getAge40Sales() != null ? entity.getAge40Sales() : 0L);
                ageSales[4] += (entity.getAge50Sales() != null ? entity.getAge50Sales() : 0L);
                ageSales[5] += (entity.getAgeOver60Sales() != null ? entity.getAgeOver60Sales()
                    : 0L);
            }
        }

        for(int i = 0; i < ageSales.length; i++){
            ageSales[i] /= 30;
            ageCnt[i] /= 30;
        }

        return CommSalesGraphDTO.builder()
            .year(salesList.get(0).getYearCode())
            .commDistrictName(salesList.get(0).getCommercialDistrictName())
            .salesCount(ageCnt)
            .sales(ageSales)
            .build();
    }

    public CommSalesGraphJsonDTO setSalesGraphJsonDto(String cacheKey, CommSalesGraphDTO dto,
        String[] category, String type) {

        ObjectNode chartData = objectMapper.createObjectNode();
        chartData.put("chartType", "bar");
        chartData.put("year", dto.getYear());
        chartData.put("commDistrictName", dto.getCommDistrictName());

        ObjectNode data = objectMapper.createObjectNode();
        ArrayNode categories = objectMapper.createArrayNode();
        ObjectNode series = objectMapper.createObjectNode();

        for (String a : category) {
            categories.add(a);
        }
        ArrayNode countData = objectMapper.createArrayNode();
        ArrayNode salesData = objectMapper.createArrayNode();
        for (Long cnt : dto.getSalesCount()) {
            countData.add(cnt);
        }
        for (Double cnt : dto.getSales()) {
            salesData.add(cnt);
            //salesData.add(String.format("%.0f", cnt));
        }
        series.set(type + "SalesCount", countData);
        series.set(type + "Sales", salesData);
        data.set("categories", categories);
        data.set("series", series);
        chartData.set("data", data);

        // 차트 데이터 캐시
        redisTemplate.opsForValue().set(cacheKey, chartData);

        return CommSalesGraphJsonDTO.builder()
            .graphJson(chartData)
            .build();
    }

    public Map<String, Double> setSalesRatioByService(List<CommEstimatedSalesEntity> salesList) {

        Map<String, Double> salesTotal = new HashMap<>();
        Map<String, Double> salesRatio = new HashMap<>();

        Double total = 0D;

        for (CommEstimatedSalesEntity entity : salesList) {
            total += entity.getMonthlySales();
            if (!salesTotal.containsKey(entity.getServiceName())) {
                salesTotal.put(entity.getServiceName(), 0D);
                Double sum = salesTotal.get(entity.getServiceName()) + entity.getMonthlySales();
                salesTotal.put(entity.getServiceName(), sum);
            } else {
                Double sum = salesTotal.get(entity.getServiceName()) + entity.getMonthlySales();
                salesTotal.put(entity.getServiceName(), sum);
            }
        }

        if (total == 0) {
            return null;
        }

        else {
            //비율 구하기
            for (Map.Entry<String, Double> entry : salesTotal.entrySet()) {
                double ratio = entry.getValue() / total;
                salesRatio.put(entry.getKey(), ratio * 100);
            }

            return salesRatio;
        }
    }
}

