package com.sc.sangchu.controller;

import com.sc.sangchu.dto.infra.CommAptDTO;
import com.sc.sangchu.dto.infra.CommStoreDTO;
import com.sc.sangchu.postgresql.service.CommInfraGraphService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/infra/graph")
@CrossOrigin
@Tag(name = "상권 환경 그래프 컨트롤러", description = "상권 환경 관련 그래프 데이터 처리 컨트롤러")
public class CommInfraGraphController {
    private final CommInfraGraphService commInfraGraphService;

    @Autowired
    public CommInfraGraphController(CommInfraGraphService commInfraGraphService) {
        this.commInfraGraphService = commInfraGraphService;
    }

    @GetMapping("/store/count")
    @Operation(summary = "특정 상권 점포 그래프 조회",
            description = "서비스업종코드와 업종 코드명, 점포 수와 프랜차이즈 점포 수 그래프를 Json 형태로 넘깁니다.")
    public ResponseEntity<CommStoreDTO> getStoreGraph(
            @RequestParam(value = "commercialDistrictCode") Long commercialDistrictCode){
        CommStoreDTO commStoreDTO = commInfraGraphService.getStoreDataAsJson(commercialDistrictCode);
        return ResponseEntity.ok(commStoreDTO);
    }

    @GetMapping("/apt/area")
    @Operation(summary = "특정 상권 아파트 면적별 세대 수 그래프 조회",
            description = "아파트 면적 별 세대 수 그래프를 JSON 형태로 넘깁니다.")
    public ResponseEntity<CommAptDTO> getAptAreaGraph(
            @RequestParam(value = "commercialDistrictCode") Long commercialDistrictCode){
        CommAptDTO commAptDTO = commInfraGraphService.getAptAreaDataAsJson(commercialDistrictCode);
        return ResponseEntity.ok(commAptDTO);
    }

    @GetMapping("/apt/price")
    @Operation(summary = "특정 상권 아파트 가격 별 세대 수 그래프 조회",
            description = "아파트 가격 별 세대 수 그래프를 JSON 형태로 넘깁니다.")
    public ResponseEntity<CommAptDTO> getAptPriceGraph(
            @RequestParam(value = "commercialDistrictCode") Long commercialDistrictCode){
        CommAptDTO commAptDTO = commInfraGraphService.getAptPriceDataAsJson(commercialDistrictCode);
        return ResponseEntity.ok(commAptDTO);
    }
}

