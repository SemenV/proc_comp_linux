module uart_sv 
 #(parameter period = 13'd5208) 
(
(* altera_attribute = "-name IO_STANDARD \"3.3-V LVCMOS\"", chip_pin = "E1"  *)
input clk,

(* altera_attribute = "-name IO_STANDARD \"3.3-V LVCMOS\"", chip_pin = "F14"  *)
input fromRX,

(* altera_attribute = "-name IO_STANDARD \"3.3-V LVCMOS\"", chip_pin = "F13"  *)
output spi_data_o,

(* altera_attribute = "-name IO_STANDARD \"3.3-V LVCMOS\"", chip_pin = "C3,A2,B3,A3,B4,A4,B5,A5" *)
output  [7:0] value,

(* altera_attribute = "-name IO_STANDARD \"3.3-V LVCMOS\"", chip_pin = "D15" *)
output error,

(* altera_attribute = "-name IO_STANDARD \"3.3-V LVCMOS\"", chip_pin = "J14" *) 
input reset
);
wire [7:0] fifo_rx_data;
wire [7:0] fifo_tx_data;
wire fifo_rx_empty;
wire rx_busy;
wire fifo_rx_rd_en;

wire tx_str;
wire tx_busy;

reg [31:0] cnt_spi_2x = 0;
reg clk_spi_2x = 0;
always_ff @ ( posedge clk)
if(( cnt_spi_2x == ( period >> 1 >> 1  ) )) begin
    cnt_spi_2x <= 13'd0;
    clk_spi_2x = ~clk_spi_2x;
  end
else
  cnt_spi_2x <= cnt_spi_2x + 1'b1;

// assign fifo_tx_data = fifo_rx_data;

spi_loopback_fsm spi_loopback_fsm_inst(
    .clk(clk_spi_2x),
    .rst_n(reset),
    .fifo_rx_data(fifo_rx_data),
    .fifo_rx_empty(fifo_rx_empty),
    .fifo_rx_rd_en(fifo_rx_rd_en),
    .rx_busy(rx_busy),

    .tx_data(fifo_tx_data),
    .tx_str(tx_str),
    .tx_busy(tx_busy),
    .stt(error)
);

uart_rx_sv uart_rx_sv_inst (
.clk_spi_2x(clk_spi_2x),
.fromRX(fromRX),
.reset(reset),
.fifo_rx_rd_en(fifo_rx_rd_en),
.fifo_rx_empty(fifo_rx_empty),
.rx_busy(rx_busy),
.fifo_rx_data(fifo_rx_data)
);


// uart_rx_sv uart_rx_sv_inst(
// .clk_spi_2x(clk_spi_2x),
// .reset(reset),
// .fromRX(fromRX),
// .busy(busy),
// .value(val)
// );

assign value = fifo_rx_data;


spi_tx spi_tx_inst (
    .clk(clk_spi_2x),      // Тактовый сигнал
    .rst_n(reset),    // Асинхронный сброс (активный 0)
    .tx_str(tx_str),   // Строб начала передачи
    .tx_data(fifo_tx_data),  // Входные данные (8 бит)
    .tx_busy(tx_busy),  // Флаг занятости
    .tx_out(spi_data_o)    // Выходная линия данных (всегда левый бит буфера)
);


// uart_tx_sv uart_tx_sv_inst (
// .clk_spi_2x(clk_spi_2x),
// .reset(reset),
// // .start_str(str_tx),
// .tx_fifo(8'h55),
// .send_end(send_end),
// .spi_data_o(spi_data_o)
// );

endmodule

// module uart_tx_sv (
//     input logic [DATA_WIDTH-1:0] tx_data,       // Данные для отправки
//     input logic                  tx_str,        // Строб старта передачи (1 такт)
//     output logic                  tx_busy        // Флаг занятости передатчика SPI







// input wire clk_spi_2x,
// input wire reset,
// // input wire start_str,
// input wire tx_fifo,
// output wire send_end,
// output wire spi_data_o

// );
// reg start_str = 0;
// reg [31:0] bit_counter = '0;
// reg [7:0] send_buf_tx = '1;

// typedef enum logic [7:0] {start_tx,cnt_send_tx,stop_tx} states_tx;
// states_tx cur_state_tx = start_tx;
// states_tx next_state_tx = start_tx;

// reg clk_spi = 0;

// always_ff @(posedge clk_spi_2x) begin
//   // if ((start_str == 1) || (next_state_tx == cnt_send_tx) || (next_state_tx == stop_tx) || (next_state_tx == start_tx))	
//     clk_spi = ~clk_spi;
//    start_str <= ~start_str; 
// end

// always_ff @(posedge clk_spi)
//   if (~reset)
//     cur_state_tx <= start_tx;
//   else
//     cur_state_tx <= next_state_tx; 

// assign send_end = ((cur_state_tx == start_tx) && (next_state_tx == start_tx) && (~start_str));

// always_ff @(posedge clk_spi)
//   if (~reset) begin
//     bit_counter <= 0;
//     spi_data_o  <= 1;
//   end
//   else if (cur_state_tx == start_tx) begin
//     send_buf_tx <= tx_fifo;
//     spi_data_o  <= 0;
//   end
//   else if (cur_state_tx == cnt_send_tx)
//     begin
//       bit_counter <= bit_counter + 1;
//       send_buf_tx <= {send_buf_tx[6:0],1'b1};
//       spi_data_o  <= send_buf_tx[7];
//     end
//     else if (cur_state_tx == stop_tx) begin
//       bit_counter <= 0;
//       send_buf_tx <= 1;
//     end
//     else begin
//       bit_counter <= 0;
//       send_buf_tx <= 1;
//     end

// always_comb begin
//   next_state_tx = cur_state_tx;
//   case(cur_state_tx)
//     start_tx: if (start_str) next_state_tx = cnt_send_tx;
//     cnt_send_tx: if (bit_counter == 7) next_state_tx = stop_tx;
//     stop_tx: next_state_tx = start_tx;
//   endcase
// end


// endmodule


module uart_rx_sv (
input wire clk_spi_2x,
input wire fromRX,
input wire reset,
input wire fifo_rx_rd_en,
output reg fifo_rx_empty = 1,
output wire rx_busy,
output wire [7:0] fifo_rx_data

);
wire trans;
reg clk_spi = 0;

reg [31:0] bit_counter = 0;
typedef enum logic [7:0] {start,count,stop} states;
states cur_state = start;
states next_state = start;


assign clk_spi_en = ((next_state == count) || (next_state == stop) || (next_state == start));
assign rx_busy = ~((cur_state == next_state) && (next_state == start));
assign trans = ((cur_state == count) && (next_state == stop));

always_ff @(posedge clk_spi_2x)	
  if (clk_spi_en)
    clk_spi = ~clk_spi;


always_ff @(posedge clk_spi_2x or negedge reset)
  if (~reset)
  fifo_rx_empty <= 1;
  else
  if (trans)
    fifo_rx_empty <= 0;
  else if (fifo_rx_rd_en)
    fifo_rx_empty <= 1;


always_ff @(posedge clk_mux or negedge reset)
  if (~reset) begin
    bit_counter <= 0;
    fifo_rx_data       <= 0;
  end
  else if (cur_state == count)
    begin
      bit_counter <= bit_counter + 1;
      fifo_rx_data       <= {fifo_rx_data[6:0],fromRX};

    end
    else
      bit_counter <= 0;



wire clk_mux;
assign clk_mux = clk_spi_en ? clk_spi : clk_spi_2x;

always_ff @(posedge clk_mux or negedge reset)
  if (~reset)
    cur_state <= start;
  else
    cur_state <= next_state; 

always_comb
  begin
    next_state = cur_state;

    case (cur_state)
      start       : if ( fromRX == 0 )    next_state = count;
      count       : if (bit_counter == 7) next_state = stop;
      stop        :                       next_state = start;
    endcase
  end
endmodule 




module spi_loopback_fsm #(
    parameter DATA_WIDTH = 8
)(
    input  logic                  clk,
    input  logic                  rst_n,       // Асинхронный сброс активным нулем

    // Интерфейс RX (приемник и FIFO)
    input  logic [DATA_WIDTH-1:0] fifo_rx_data,  // Данные с выхода FIFO
    input  logic                  fifo_rx_empty, // Флаг пустоты FIFO (опционально, но рекомендуется)
    output logic                  fifo_rx_rd_en, // Строб чтения из FIFO
    input  logic                  rx_busy,       // Флаг занятости приемника SPI

    // Интерфейс TX (передатчик)
    output logic [DATA_WIDTH-1:0] tx_data,       // Данные для отправки
    output logic                  tx_str,        // Строб старта передачи (1 такт)
    input  logic                  tx_busy,        // Флаг занятости передатчика SPI
    output logic stt = 0
);

    // Определение состояний автомата
    typedef enum logic [2:0] {
        ST_IDLE_RX,      // Ожидание завершения приема и наличия данных
        ST_READ_FIFO,    // Формирование строба чтения из FIFO
        ST_LATCH_DATA,   // Фиксация данных (ожидание 1 такт для стандартного FIFO)
        ST_SEND_TX,      // Проверка готовности TX и запуск передачи
        ST_WAIT_TX_START,// Ожидание установки флага tx_busy
        ST_WAIT_TX_DONE  // Ожидание завершения передачи (сброса tx_busy)
    } state_t;
    

    state_t state, next_state;
    logic [DATA_WIDTH-1:0] data_reg;

    always_ff @(posedge clk, negedge rst_n)
    if (~rst_n )
    stt <= 0;
    else
      if (state == ST_WAIT_TX_DONE) 
        stt <= 1;


    // 1. Регистр состояния
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= ST_IDLE_RX;
        else
            state <= next_state;
    end

    // 2. Логика переходов
    always_comb begin
        next_state = state;
        case (state)
            ST_IDLE_RX: begin
                // Ждем, пока приемник освободится и в FIFO появятся данные
                if (!rx_busy && !fifo_rx_empty)
                    next_state = ST_READ_FIFO;
            end

            ST_READ_FIFO: begin
                // Выставляем сигнал чтения на 1 такт
                next_state = ST_LATCH_DATA;
            end

            ST_LATCH_DATA: begin
                // На этом такте данные из FIFO уже валидны, переходим к отправке
                next_state = ST_SEND_TX;
            end

            ST_SEND_TX: begin
                // Ждем, пока передатчик освободится
                if (!tx_busy)
                    next_state = ST_WAIT_TX_START;
            end

            ST_WAIT_TX_START: begin
                // Ждем реакции от модуля TX (поднятия tx_busy), 
                // чтобы не проскочить состояние до начала передачи
                if (tx_busy)
                    next_state = ST_WAIT_TX_DONE;
            end

            ST_WAIT_TX_DONE: begin
                // Ждем окончания передачи по SPI
                if (!tx_busy)
                    next_state = ST_IDLE_RX;
            end

            default: next_state = ST_IDLE_RX;
        endcase
    end

    // 3. Формирование выходных сигналов и захват данных
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_rx_rd_en <= 1'b0;
            tx_str        <= 1'b0;
            tx_data       <= '0;
            data_reg      <= '0;
        end else begin
            // По умолчанию сбрасываем импульсные сигналы
            fifo_rx_rd_en <= 1'b0;
            tx_str        <= 1'b0;

            case (state)
                ST_READ_FIFO: begin
                    fifo_rx_rd_en <= 1'b1; // Запрашиваем слово из FIFO
                end

                ST_LATCH_DATA: begin
                    data_reg <= fifo_rx_data; // Сохраняем прочитанное слово
                end

                ST_SEND_TX: begin
                    if (!tx_busy) begin
                        tx_data <= data_reg; // Выставляем данные на шину TX
                        tx_str  <= 1'b1;     // Формируем строб отправки на 1 такт
                    end
                end
            endcase
        end
    end

endmodule


module spi_tx (
    input  wire       clk,      // Тактовый сигнал
    input  wire       rst_n,    // Асинхронный сброс (активный 0)
    input  wire       tx_str,   // Строб начала передачи
    input  wire [7:0] tx_data,  // Входные данные (8 бит)
    output reg        tx_busy,  // Флаг занятости
    output wire       tx_out    // Выходная линия данных (всегда левый бит буфера)
);

wire clk_mux_tx;
reg clk_spi_tx;
wire clk_mux_en;

typedef enum logic [7:0] {STATE_START,STATE_WRITE,STATE_STOP} states_tx;
states_tx cur_state_tx = STATE_START;
states_tx next_state_tx = STATE_START;


always_ff @(posedge clk)
  if (clk_mux_en)
    clk_spi_tx = ~clk_spi_tx;

assign clk_mux_en = ((cur_state_tx == STATE_START && next_state_tx == STATE_WRITE) || (cur_state_tx == STATE_WRITE) || (cur_state_tx == STATE_STOP));

assign clk_mux_tx = clk_mux_en ? clk_spi_tx : clk;


    // Внутренние управляющие сигналы от автомата к тракту данных
    reg load_en;   // Разрешение записи в буфер (включая стартовый 0)
    reg shift_en;  // Разрешение сдвига и счёта

    // Регистры тракта данных
    reg [7:0] tx_buf;   // 9-битный буфер: [8] - стартовый бит, [7:0] - данные
    reg [2:0] bit_cnt;  // Счётчик записи на 8 бит (0..7)

    always_ff @(posedge clk_mux_tx or negedge rst_n)
      if (~rst_n)
        tx_out <= 1'b1;
		else 
      if ((cur_state_tx == STATE_START) && (next_state_tx == STATE_WRITE))
        tx_out <= 1'b0;
      else if (cur_state_tx == STATE_STOP) 
        tx_out <= 1'b1;
      else if (cur_state_tx == STATE_WRITE)
        tx_out <= tx_buf[7];
      else
        tx_out <= 1;
    

    // =========================================================================
    // 1. ПЕРВАЯ ЧАСТЬ FSM: Переключение состояний (последовательностная логика)
    // =========================================================================
    always @(posedge clk_mux_tx or negedge rst_n) begin
        if (!rst_n)
            cur_state_tx <= STATE_START;
        else
            cur_state_tx <= next_state_tx;
    end

    // =========================================================================
    // 2. ВТОРАЯ ЧАСТЬ FSM: Комбинационная схема переходов и управления
    // =========================================================================
    always @(*) begin
        next_state_tx = cur_state_tx;
        load_en    = 1'b0;
        shift_en   = 1'b0;
        tx_busy    = 1'b0;

        case (cur_state_tx)
            STATE_START: begin
                if (tx_str) begin
                    load_en    = 1'b1;        // Загружаем {1'b0, tx_data} в буфер
                    tx_busy    = 1'b1;        // Выставляем busy
                    next_state_tx = STATE_WRITE; // Переход в запись
                end else begin
                    tx_busy    = 1'b0;
                    next_state_tx = STATE_START;
                end
            end

            STATE_WRITE: begin
                shift_en = 1'b1;              // Сдвигаем буфер и считаем 8 бит
                tx_busy  = 1'b1;

                if (bit_cnt == 3'd7)
                    next_state_tx = STATE_STOP;  // Отсчитали 8 бит -> на стоп
                else
                    next_state_tx = STATE_WRITE;
            end

            STATE_STOP: begin
                // shift_en   = 1'b1;            // Выдвигаем последний 8-й бит, на выход встаёт 1 (стоп)
                tx_busy    = 1'b1;            // Занят во время передачи стоп-бита
                next_state_tx = STATE_START;     // Возврат в начало
            end

            default: begin
                next_state_tx = STATE_START;
            end
        endcase
    end

    // =========================================================================
    // 3. ВЫНЕСЕННАЯ ЛОГИКА: Передающий буфер и счётчик на 8 бит
    // =========================================================================
    always @(posedge clk_mux_tx or negedge rst_n) begin
        if (!rst_n) begin
            tx_buf  <= 8'hFF;                // При сбросе буфер заполнен 1'b1
            bit_cnt <= 3'd0;
        end else begin
            if (load_en) begin
                tx_buf  <= {tx_data};   // Записываем стартовый 0 и 8 бит данных
                bit_cnt <= 3'd0;              // Сбрасываем счётчик
            end else if (shift_en) begin
                tx_buf  <= {tx_buf[6:0], 1'b1}; // Сдвиг справа налево с заполнением 1'b1
                bit_cnt <= bit_cnt + 3'd1;      // Увеличиваем счётчик бит
            end
        end
    end

endmodule