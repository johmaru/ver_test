interface imem_if;
  logic        req_valid;
  logic [31:0] req_addr;
  logic        req_ready;

  logic        resp_valid;
  logic [31:0] resp_data;
  logic        resp_ready;

  modport master (
            output req_valid,
            output req_addr,
            output resp_ready,
            input  req_ready,
            input  resp_valid,
            input  resp_data
          );


  modport slave (
            input  req_valid,
            input  req_addr,
            input  resp_ready,
            output req_ready,
            output resp_valid,
            output resp_data
          );
endinterface
