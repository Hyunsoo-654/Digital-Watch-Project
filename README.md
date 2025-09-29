# Final UART-Controled Sensor & Watch / Stopwatch System on FPGA 
## 📝 Overview
본 프로젝트는 ** UART 통신 기반 Basys-3 및 switch & Button으로 디지털 시계 및 스톱워치, SR04, DHT11 센서 기능을 제어**하는 FPGA 시스템입니다.

명령은 FIFO를 통해 안정적으로 처리되며, Verilog로 구현된 여러 모듈들이 유기적으로 동작하여 시계 모드와 스톱워치 모드를 전환 및 제어합니다.

## 🎯 Features
- **UART 통신 지원**: PC에서 보낸 명령(R, C, H, M, S)을 수신 및 처리
- **FIFO 버퍼링**: 수신 데이터의 안정적 처리
- **명령어 처리기 (CMD_PROCESSOR)**: 명령 해석 및 버튼 신호 생성
- **Watch & Stopwatch 기능 통합**
- **디지털 디스플레이(FND) 출력**
- **SR04**: 버튼을 통해 측정한 값이 UART 통신을 통해 `Temp: xx'C, Humid: xx%` 형태로 출력됩니다.
- **DHT11**: 버튼을 통해 측정한 값이 UART 통신을 통해 `Distance:xxcm` 형태로 출력됩니다

## 🛠️ Architecture
- `UART_RX`: PC로부터 데이터를 수신
- `UART_TX`: FPGA에서 데이터를 송신 (테스트용)
- `UART_FIFO`: 수신 데이터를 저장하는 FIFO 버퍼
- `command_to_btn`: 명령에 대응하는 버튼 시그널 출력 (run, clear, hour, min, sec, Mode 등..)
- `watch`, `stopwatch`: 실시간 시계 및 스톱워치 동작 담당
-  `DHT11`, `SR04`: 온습도 및 거리 측정 센서를 담당

## B📡 Supported Commands (via UART)
| Command | 기능          | 출력 신호 |
|---------|---------------|-----------|
| R       | 스톱워치 시작   | run       |
| S       | 스톱워치 정지   | Stop      |
| C       | 스톱워치 초기화 | clear     |
| U       | 값 UP         |   u        |
| D       | 값 Down       |  d         |
| L       | 시분초 설정    | L      |
| ESC     | reset         | ESC       |
| M,N    | 모드 전환(DHT11, SRo4, 시계, 스탑워치)|  N,M |

각 명령은 ASCII 코드로 입력됩니다. (R = 0x52, C = 0x43, ...)

## 🖼️ Block Diagram
![alt text](immage/image.png)


## 🧹 개선 사항
초기 버전에서 SetUp Time Violation 발생
1. SR04 및 DHT11 Sender 에서 너무 많은 case문을 사용  
2. counter에서 큰 숫자를 %58 연산 사용

```
DONE: begin
    dist_next = duration_reg / 58;
    done_next = 1;
    next_state = IDLE;
end
```

개선 후: 
```
DIVIDE: begin
    // shift-and-subtract divider for division by 58
    if (dividend_reg >= 58) begin
        dividend_next = dividend_reg - 58;
        quotient_next = quotient_reg + 1;
    end else begin
        state_next = DONE;
    end
end
```
case 문을 if문을 수정하여 더 빠르게 수정
```
PREPARE: begin
    if (!prepare_done) begin
        if (btn_sender_up) begin
            message_buffer[0]  = "T";
            message_buffer[1]  = "e";
            message_buffer[2]  = "m";
            message_buffer[3]  = "p";
            message_buffer[4]  = ":";
            message_buffer[5]  = " ";
            message_buffer[6]  = temp_ascii[0];
            message_buffer[7]  = temp_ascii[1];
            message_buffer[8]  = "'";
            message_buffer[9]  = "C";
            message_buffer[10] = ",";
            message_buffer[11] = " ";
            message_buffer[12] = "H";
            message_buffer[13] = "u";
            message_buffer[14] = "m";
            message_buffer[15] = "i";
            message_buffer[16] = "d";
            message_buffer[17] = ":";
            message_buffer[18] = " ";
            message_buffer[19] = humi_ascii[0];
            message_buffer[20] = humi_ascii[1];
            message_buffer[21] = "%";
            message_buffer[22] = "\n";
            msg_len_reg = 23;
        end else begin
            message_buffer[0]  = "D";
            message_buffer[1]  = "i";
            message_buffer[2]  = "s";
            message_buffer[3]  = "t";
            message_buffer[4]  = "a";
            message_buffer[5]  = "n";
            message_buffer[6]  = "c";
            message_buffer[7]  = "e";
            message_buffer[8]  = ":";
            message_buffer[9]  = w_send_dist_data[31:24];
            message_buffer[10] = w_send_dist_data[23:16];
            message_buffer[11] = w_send_dist_data[15:8];
            message_buffer[12] = w_send_dist_data[7:0];
            message_buffer[13] = "c";
            message_buffer[14] = "m";
            message_buffer[15] = "\n";
            msg_len_reg = 16;
        end
        prepare_done_next = 1;
    end else begin
        next_state = LOAD;
    end
end
```
