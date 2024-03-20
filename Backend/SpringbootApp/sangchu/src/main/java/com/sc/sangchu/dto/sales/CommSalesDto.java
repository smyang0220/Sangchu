package com.sc.sangchu.dto.sales;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CommSalesDto {
    //월평균, 주중, 주말 매출 금액
    private Long MonthlySales;
    private Long WeekDaySales;
    private Long WeekendSales;
}