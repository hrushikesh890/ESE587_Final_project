module pla(pla_select, clk, reset, valid_in, valid_in_rev, x, valid_out, valid_out_rev, out);
	input pla_select,clk,reset,valid_in,valid_in_rev;
	input logic [31:0] x;
	output logic valid_out,valid_out_rev;
	output logic [31:0] out;
    
    sigmoid_tanh sigtan1(pla_select, clk, reset, valid_in, valid_in_rev, x, valid_out, valid_out_rev, out);
endmodule

module sigmoid_tanh(pla_select, clk, reset, valid_in, valid_in_rev, x, valid_out, valid_out_rev, out);
	input pla_select,clk,reset,valid_in,valid_in_rev;
	input logic [31:0] x;
	output logic valid_out,valid_out_rev;
	output logic [31:0] out;
	
	logic[31:0] m0,m1,m2,c0,c1;
	logic[31:0] bias1,bias2,bias3;
	logic[31:0] temp,temp2,temp3;
	logic[31:0] x_pos;	
	logic[31:0] mult_multiply1_value,mult_multiply2_value,add_output_value;
	logic[31:0] tanm0,tanm1,tanm2,tanb1,tanb2,tanb3,tanmul;

	assign m0 = 32'h3e51eb85; //0.205
	assign m1 = 32'h3d99999a; //0.075
	assign m2 = 32'h3c8b4396; //0.017
	assign c0 = 32'h3fd5c28f; //1.67
	assign c1 = 32'h40551eb8; //3.33
	assign bias1 = 32'h3f000000; //0.5
	assign bias2 = 32'h3f378d50; //0.717
    assign bias3 = 32'h3f68f5c3; //0.91
    assign tanm0 = 32'h3ed1eb85; //0.41
    assign tanm1 = 32'h3e19999a; //0.15
    assign tanm2 = 32'h3d0b4396; //0.034
    assign tanb1 = 32'h00000000; //0
    assign tanb2 = 32'h3ede353f; //0.434
    assign tanb3 = 32'h3f51eb85; //0.82
    assign tanmul = 32'h40800000; //4
    
    float_absolute_value abs1(clk, reset, valid_in_rev, valid_out_rev, x, x_pos);	

    always_comb begin
        if(pla_select == 1) begin  //sigmoid
			if((x_pos > 0) && (x_pos < c0)) begin
			    mult_multiply1_value = m0;
			    mult_multiply2_value = x;
			    add_output_value = bias1;
			end
			else if((x_pos >= c0)  && (x_pos < c1)) begin
			    mult_multiply1_value = m1;
			    mult_multiply2_value = x;
			    add_output_value = bias2;               
			end
			else if(x_pos > c1) begin
                mult_multiply1_value = m2;
			    mult_multiply2_value = x;
			    add_output_value = bias3;		    
			end				
			else begin
                mult_multiply1_value = 32'h00000000;
			    mult_multiply2_value = 32'h00000000;
			    add_output_value = 32'h00000000;		
			end     			
		end		
		else begin  //tanh
			if((x_pos > 0) && (x_pos < c0)) begin
			    mult_multiply1_value = tanm0;
			    mult_multiply2_value = x;
			    add_output_value = tanb1;
			end
			else if((x_pos >= c0)  && (x_pos < c1)) begin
			    mult_multiply1_value = tanm1;
			    mult_multiply2_value = x;
			    add_output_value = tanb2;               
			end
			else if(x_pos > c1) begin
                mult_multiply1_value = tanm2;
			    mult_multiply2_value = x;
			    add_output_value = tanb3;		    
			end				
			else begin
                mult_multiply1_value = 32'h00000000;
			    mult_multiply2_value = 32'h00000000;
			    add_output_value = 32'h00000000;		
			end 		
		end
	end
	
    multiply_and_add mad1(clk, reset, valid_in, valid_out, mult_multiply1_value, mult_multiply2_value, add_output_value, out); 
endmodule


module multiply_and_add(clk, reset, valid_in, valid_out, in0, in1, in2, out0);
	input clk, reset, valid_in;
    output logic valid_out;
    input [31:0] in0, in1, in2;
    output logic [31:0] out0;

    logic [31:0] in0_reg, in1_reg, in2_reg, out_tmp;
    logic valid_reg, valid_tmp; 


    always_ff @(posedge clk) begin
        if (reset == 1'b1) begin
            in0_reg <= 0;
            in1_reg <= 0; 
            in2_reg <= 0; 
                  
            valid_reg <= 0;
        end
        else begin
            in0_reg <= in0;
            in1_reg <= in1;
            in2_reg <= in2;
            valid_reg <= valid_in;
        end
    end
	
	fp_add0 fp1 (                       
        .s_axis_a_tvalid(valid_reg),      
        .s_axis_a_tdata(in0_reg),
        .s_axis_b_tvalid(valid_reg),
        .s_axis_b_tdata(in1_reg),
	    .s_axis_c_tvalid(valid_reg),
	    .s_axis_c_tdata(in2_reg),
	    .m_axis_result_tvalid(valid_tmp),
        .m_axis_result_tdata(out_tmp)
	);

	always_ff @(posedge clk) begin
        if (reset == 1'b1) begin
            out0 <= 0;
            valid_out = 0;
        end
        else begin
            out0 <= out_tmp;
            valid_out <= valid_tmp;
        end
    end
endmodule

module float_absolute_value(clk, reset, valid_in, valid_out, in0, out0);
    input clk, reset, valid_in;
    output logic valid_out;
    input [31:0] in0;
    output logic [31:0] out0;

    logic [31:0] in0_reg, out_tmp;
    logic valid_reg, valid_tmp; 


    always_comb begin
        if (reset == 1'b1) begin
            in0_reg <= 0;           
            valid_reg <= 0;
        end
        else begin
            in0_reg <= in0;
            valid_reg <= valid_in;
        end
    end

    myabsolutevalue absolute_value_inst (                   
        .s_axis_a_tvalid(valid_reg),      
        .s_axis_a_tdata(in0_reg),
        .m_axis_result_tvalid(valid_tmp),
        .m_axis_result_tdata(out_tmp)
    );

    always_comb begin
        if (reset == 1'b1) begin
            out0 <= 0;
            valid_out = 0;
        end
        else begin
            out0 <= out_tmp;
            valid_out <= valid_tmp;
        end
    end
endmodule