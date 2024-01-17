module gate_module(clk, reset, ps_control, pl_status, in0, in1, in2, in3, in4, in5, in6, in7, in8, in9, out0, bram_wren, in_addr, out_addr);
	input clk, reset;
	input  [31:0] ps_control;
	output logic [31:0] pl_status, out0;
	input [31:0] in0, in1, in2, in3, in4, in5, in6, in7, in8, in9;
	output logic [11:0] in_addr, out_addr;
	output logic [3:0] bram_wren;
	logic [31:0] m_out0, m_out1, m_out2, m_out3, m_out4, m_out5, m_out6, m_out7;
	logic [31:0] m_out0_reg, m_out1_reg/*, m_out2_reg, m_out3_reg, m_out4_reg, m_out5_reg, m_out6_reg, m_out7_reg*/;
	logic m_valid_in, mac_clr, m_valid_out0, m_valid_out1, m_valid_out2, m_valid_out3, m_valid_out4, m_valid_out5, m_valid_out6, m_valid_out7, valid_out, write_out, write_done;

	mac m1(.clk(clk), .reset(mac_clr), .valid_in(m_valid_in), .valid_out(m_valid_out0), .in0(in0), .in1(in1), .out0(m_out0));
	mac m2(.clk(clk), .reset(mac_clr), .valid_in(m_valid_in), .valid_out(m_valid_out1), .in0(in2), .in1(in3), .out0(m_out1));
	mac m3(.clk(clk), .reset(mac_clr), .valid_in(m_valid_in), .valid_out(m_valid_out2), .in0(in0), .in1(in4), .out0(m_out2));
	mac m4(.clk(clk), .reset(mac_clr), .valid_in(m_valid_in), .valid_out(m_valid_out3), .in0(in2), .in1(in5), .out0(m_out3));
	mac m5(.clk(clk), .reset(mac_clr), .valid_in(m_valid_in), .valid_out(m_valid_out4), .in0(in0), .in1(in6), .out0(m_out4));
	mac m6(.clk(clk), .reset(mac_clr), .valid_in(m_valid_in), .valid_out(m_valid_out5), .in0(in2), .in1(in7), .out0(m_out5));
	mac m7(.clk(clk), .reset(mac_clr), .valid_in(m_valid_in), .valid_out(m_valid_out6), .in0(in0), .in1(in8), .out0(m_out6));
	mac m8(.clk(clk), .reset(mac_clr), .valid_in(m_valid_in), .valid_out(m_valid_out7), .in0(in2), .in1(in9), .out0(m_out7));
	memory_router mem3 (.clk(clk), .rst(reset), .in0_addr(in_addr), .mac_start(m_valid_in), .mac_clr(mac_clr), .start_write(valid_out), .pl_status(pl_status), .ps_control(ps_control), .write_out(write_out), .write_done(write_done));
	
	always_ff @(posedge clk) begin
		if (reset == 1 || pl_status == 1) begin
			out_addr <= 0;
		end
		else if (write_out == 1) begin 
			out_addr <= out_addr + 4;
		end
		else begin
			out_addr <= out_addr;
		end
	end

	always_ff @(posedge clk) begin
		if (reset == 1 || pl_status == 1) begin
			m_out0_reg <= 0; 
			m_out1_reg <= 0;
			// Some outputs have been commented out to save LUTs. It does not affect the rutime it just does not give results for 6 MACs
			/*m_out2_reg <= 0;
			m_out3_reg <= 0;
			m_out4_reg <= 0;
			m_out5_reg <= 0;
			m_out6_reg <= 0;
			//m_out7_reg <= 0;*/
		end
		else if (valid_out == 1) begin 
			m_out0_reg <= m_out0; 
			m_out1_reg <= m_out1;
			/*m_out2_reg <= m_out2;
			m_out3_reg <= m_out3;
			m_out4_reg <= m_out4;
			m_out5_reg <= m_out5;
			m_out6_reg <= m_out6;
			//m_out7_reg <= m_out7;*/
		end
		else begin
			m_out0_reg <= m_out0_reg; 
			m_out1_reg <= m_out1_reg;
			/*m_out2_reg <= m_out2_reg;
			m_out3_reg <= m_out3_reg;
			m_out4_reg <= m_out4_reg;
			m_out5_reg <= m_out5_reg;
			m_out6_reg <= m_out6_reg;
			//m_out7_reg <= m_out7_reg;*/
		end
	end

	always_comb begin
		if (out_addr == 0)
			out0 = m_out0_reg;
		else if (out_addr == 4)
			out0 = m_out1_reg;
		/*else if (out_addr == 8)
			out0 = m_out2_reg;
		else if (out_addr == 12)
			out0 = m_out3_reg;
		else if (out_addr == 16)
			out0 = m_out4_reg;
		else if (out_addr == 20)
			out0 = m_out5_reg;
		else if (out_addr == 24)
			out0 = m_out6_reg;
		//else if (out_addr == 28)
			//out0 = m_out7_reg;*/
		else
			out0 = 0;
	end
	assign bram_wren = (write_out == 1) ? 4'hf:4'h0;
	assign write_done = (out_addr == 24) ? 1:0;
endmodule

module mac(clk, reset, valid_in, valid_out, in0, in1, out0);
	input clk, reset, valid_in;
    output logic valid_out;
    input [31:0] in0, in1;
    output logic [31:0] out0;

    logic [31:0] in0_reg, in1_reg, out_tmp;
    logic valid_reg, valid_tmp; 


    always_ff @(posedge clk) begin
        if (reset == 1'b1) begin
            in0_reg <= 0;
            in1_reg <= 0;        
            valid_reg <= 0;
        end
        else begin
            in0_reg <= in0;
            in1_reg <= in1;
            valid_reg <= valid_in;
        end
    end
	
	fp_add0 fp1 (                       
        .s_axis_a_tvalid(valid_reg),      
        .s_axis_a_tdata(in0_reg),
        .s_axis_b_tvalid(valid_reg),
        .s_axis_b_tdata(in1_reg),
	    .s_axis_c_tvalid(valid_reg),
	    .s_axis_c_tdata(out0),
	    .m_axis_result_tvalid(valid_tmp),
        .m_axis_result_tdata(out_tmp)
	);

	always_ff @(posedge clk) begin
        if (reset == 1'b1) begin
            out0 <= 0;
            valid_out <= 0;
        end
        else begin
            out0 <= out_tmp;
            valid_out <= valid_tmp;
        end
    end
endmodule


module memory_router(clk, rst, in0_addr, mac_start, mac_clr, start_write, pl_status, ps_control, write_out, write_done);
	input clk, rst;
	output logic [11:0] in0_addr;
	output logic [31:0] pl_status;
	input [31:0] ps_control;
	output logic mac_start, start_write, mac_clr, write_out;
	input write_done;

	logic [2:0] curr_state, next_state;
	logic incr_addr;

	always_ff @(posedge clk) begin
		if (rst == 1) begin
			curr_state <= 0;
		end
		else
			curr_state <= next_state;
	end

	always_comb begin
		if (curr_state == 0) begin
			if (ps_control[0] == 1)
				next_state = 1; // memory increment start
			else
				next_state = 0; // do nothing
		end 

		else if (curr_state == 1) 
			next_state = 2; // mac start

		else if (curr_state == 2) begin
			next_state = 3; // op write start
		end

		else if (curr_state == 3) begin
			if (in0_addr == 2044)
				next_state = 4; // stop memory incr
			else
				next_state = 3;
		end

		else if (curr_state == 4) begin
			next_state = 5; // stop memory write
		end 

		else if (curr_state == 5) begin
			next_state = 7; // all _done

		end
		else if (curr_state == 7) begin
			if (write_done == 1)
                    next_state = 6; // all _done
            else
            	next_state = 7;
        
        end

		else if (curr_state == 6) begin
			if (ps_control[0] == 1)
				next_state = 6;
			else
				next_state = 0;
		end
	end
		
	always_ff @(posedge clk) begin
		if (rst == 1) begin
			in0_addr <= 0;
		end
		else if (incr_addr == 1)
			in0_addr <= in0_addr + 4;
		else
			in0_addr <= in0_addr;
	end

	assign incr_addr = (curr_state == 1 || curr_state == 2 || curr_state == 3) ? 1:0;
	assign mac_start = (curr_state == 2 || curr_state == 3 || curr_state == 4 /*|| curr_state == 5*/) ? 1:0;
	assign start_write = (curr_state == 5) ? 1:0;
	assign write_out = (curr_state == 7) ? 1:0;
	assign pl_status = (curr_state == 6) ? 1:0;
	assign mac_clr = (curr_state == 0) ? 1:0;

endmodule