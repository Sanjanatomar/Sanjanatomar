`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// I2C Master Testbench with Multiple Test Cases
//////////////////////////////////////////////////////////////////////////////////

module i2c_master_tb;
    // Signal declarations
    wire sda;
    wire scl;
    wire clkdummy, rw;
    reg clk100mhz, res;
    reg [7:0] data_to_send, addr_to_send;
    reg sda_in;
    
    // Test status tracking
    integer test_case;
    integer errors;
    
    // Instantiate the DUT
    i2c_master dut(
        .sda(sda),
        .scl(scl),
        .clk100mhz(clk100mhz),
        .res(res),
        .data_to_send(data_to_send),
        .addr_to_send(addr_to_send),
        .clkdummy(clkdummy),
        .rw(rw)
    );
    
    // Assign sda tristate control
    assign sda = sda_in;
    
    // Clock generation
    always #5 clk100mhz = ~clk100mhz;
    
    // Monitor I2C bus activity
    task monitor_i2c;
        begin
            $display("Time=%0t: SCL=%b SDA=%b", $time, scl, sda);
        end
    endtask
    
    // Task to simulate ACK from slave
    task slave_ack;
        begin
            @(negedge scl);
            #100 sda_in = 0;  // Pull SDA low for ACK
            @(posedge scl);
            @(negedge scl);
            #100 sda_in = 1'bZ;  // Release SDA
        end
    endtask
    
    // Task to simulate NACK from slave
    task slave_nack;
        begin
            @(negedge scl);
            #100 sda_in = 1'bZ;  // Keep SDA high for NACK
            @(posedge scl);
            @(negedge scl);
        end
    endtask
    
    // Test scenario tasks
    task test_write_transaction;
        input [7:0] addr;
        input [7:0] data;
        begin
            // Start Write Transaction
            $display("\nTest Case %0d: Write Transaction", test_case);
            $display("Address: 0x%h, Data: 0x%h", addr, data);
            
            addr_to_send = addr;
            data_to_send = data;
            
            // Wait for start condition
            @(negedge sda);
            
            // Send ACK after address
            slave_ack();
            
            // Send ACK after data
            slave_ack();
            
            // Wait for stop condition
            @(posedge sda);
            
            $display("Write Transaction Complete");
        end
    endtask
    
    // Main test sequence
    initial begin
        // Initialize signals
        clk100mhz = 0;
        res = 1;
        sda_in = 1'bZ;
        test_case = 0;
        errors = 0;
        
        // Add wave monitoring
        $dumpfile("i2c_master_tb.vcd");
        $dumpvars(0, i2c_master_tb);
        
        // Test Case 1: Basic Write
        test_case = 1;
        #250 res = 0;
        test_write_transaction(8'h98, 8'h55);
        
        // Test Case 2: Another Write with different data
        #1000;
        test_case = 2;
        test_write_transaction(8'h96, 8'hAA);
        
        // Test Case 3: Write with NACK response
        #1000;
        test_case = 3;
        $display("\nTest Case %0d: Write with NACK", test_case);
        addr_to_send = 8'h94;
        data_to_send = 8'h33;
        
        @(negedge sda);  // Wait for start
        slave_nack();    // NACK the address
        @(posedge sda);  // Wait for stop
        
        // End simulation
        #2000;
        $display("\nSimulation completed with %0d errors", errors);
        $finish;
    end
    
    // Monitor bus activity throughout the simulation
    always @(posedge clk100mhz) begin
        monitor_i2c();
    end
    
endmodule
