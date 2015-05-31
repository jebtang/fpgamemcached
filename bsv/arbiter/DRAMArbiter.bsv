package DRAMArbiter;

import FIFO::*;
import FIFOF::*;
import Vector::*;
import GetPut::*;
import ClientServer::*;
import Connectable::*;
//import Arbiter::*;
import MyArbiter::*;

import DRAMCommon::*;
import DRAMController::*;

interface DRAMArbiterIfc#(numeric type numServers);
   interface Vector#(numServers, DRAMServer) dramServers;
   interface DRAMClient dramClient;
endinterface

interface DRAM_LOCK_Arbiter_Bypass#(numeric type numServers);
   interface Vector#(numServers, DRAM_LOCK_Server) dramServers;
   interface DRAM_LOCK_Client dramClient;
endinterface

      
module mkDRAMArbiter(DRAMArbiterIfc#(numServers));
   
   Arbiter_IFC#(numServers) arbiter <- mkArbiter(False);
   
   Vector#(numServers, FIFOF#(DRAMReq)) reqs<- replicateM(mkFIFOF);
   Vector#(numServers, FIFO#(Bit#(512))) resps<- replicateM(mkFIFO);
   
   FIFO#(DRAMReq) cmdQ <- mkFIFO;
   FIFO#(Bit#(512)) dataQ <- mkFIFO;
   
   FIFO#(Bit#(TLog#(numServers))) tagQ <- mkSizedFIFO(32);
   
   
   for (Integer i = 0; i < valueOf(numServers); i = i + 1) begin
      rule doReqs_0 if (reqs[i].notEmpty);
         arbiter.clients[i].request;
      endrule
      
      rule doReqs_1 if (arbiter.grant_id == fromInteger(i));
         let req <- toGet(reqs[i]).get();
         cmdQ.enq(req);
         if (req.rnw) begin
            tagQ.enq(fromInteger(i));
         end
      endrule
      
      rule doResp if ( tagQ.first() == fromInteger(i));
         let data = dataQ.first;
         resps[i].enq(data);
         tagQ.deq();
         dataQ.deq();
      endrule
   end
   
   
   Vector#(numServers, DRAMServer) ds;
   for (Integer i = 0; i < valueOf(numServers); i = i + 1)
      ds[i] = (interface DRAMServer;
                  interface Put request = toPut(reqs[i]);
                  interface Get response = toGet(resps[i]);
               endinterface);
   
   interface dramServers = ds;
   
   interface DRAMClient dramClient;
      interface Get request = toGet(cmdQ);
      interface Put response = toPut(dataQ);
   endinterface
      
endmodule

module mkDRAM_LOCK_Arbiter_Bypass(DRAM_LOCK_Arbiter_Bypass#(numServers));
   
   Arbiter_IFC#(numServers) arbiter <- mkArbiter(False);
   
   Vector#(numServers, FIFOF#(DRAM_LOCK_Req)) reqs<- replicateM(mkFIFOF);
   Vector#(numServers, FIFO#(Bit#(512))) resps<- replicateM(mkFIFO);
   
   FIFO#(DRAM_LOCK_Req) cmdQ <- mkFIFO;
   FIFO#(Bit#(512)) dataQ <- mkFIFO;
   
   FIFO#(Bit#(TLog#(numServers))) tagQ <- mkSizedFIFO(32);
   
   
   for (Integer i = 0; i < valueOf(numServers); i = i + 1) begin
      rule doReqs_0 if (reqs[i].notEmpty);
         arbiter.clients[i].request;
      endrule
      
      rule doReqs_1 if (arbiter.grant_id == fromInteger(i));
         let req <- toGet(reqs[i]).get();
         cmdQ.enq(req);
         if (req.rnw) begin
            tagQ.enq(fromInteger(i));
         end
      endrule
      
      rule doResp if ( tagQ.first() == fromInteger(i));
         let data = dataQ.first;
         resps[i].enq(data);
         tagQ.deq();
         dataQ.deq();
      endrule
   end
   
   
   Vector#(numServers, DRAM_LOCK_Server) ds;
   for (Integer i = 0; i < valueOf(numServers); i = i + 1)
      ds[i] = (interface DRAM_LOCK_Server;
                  interface Put request = toPut(reqs[i]);
                  interface Get response = toGet(resps[i]);
               endinterface);
   
   interface dramServers = ds;
   
   interface DRAM_LOCK_Client dramClient;
      interface Get request = toGet(cmdQ);
      interface Put response = toPut(dataQ);
   endinterface
      
endmodule

typedef DRAM_LOCK_Arbiter_Bypass#(2) DRAM_LOCK_Biased_Arbiter;

module mkDRAM_LOCK_Biased_Arbiter_Bypass(DRAM_LOCK_Biased_Arbiter);
   
   Arbiter_IFC#(2) arbiter <- mkArbiter(True);
   
   Vector#(2, FIFOF#(DRAM_LOCK_Req)) reqs<- replicateM(mkFIFOF);
   Vector#(2, FIFO#(Bit#(512))) resps<- replicateM(mkFIFO);
   
   FIFO#(DRAM_LOCK_Req) cmdQ <- mkFIFO;
   FIFO#(Bit#(512)) dataQ <- mkFIFO;
   
   FIFO#(Bit#(1)) tagQ <- mkSizedFIFO(32);
   
   

   rule doReqs_0 if (reqs[0].notEmpty);
      arbiter.clients[0].request;
   endrule
   
   rule doReqs_1 if (reqs[1].notEmpty);
      if ( !reqs[0].notEmpty ) begin
         arbiter.clients[1].request;
      end
   endrule
   
   for (Integer i = 0; i < 2; i = i + 1) begin      
      rule doDeqReqs if (arbiter.grant_id == fromInteger(i));
         let req <- toGet(reqs[i]).get();
         cmdQ.enq(req);
         if (req.rnw) begin
            tagQ.enq(fromInteger(i));
         end
      endrule
      
      rule doResp if ( tagQ.first() == fromInteger(i));
         let data = dataQ.first;
         resps[i].enq(data);
         tagQ.deq();
         dataQ.deq();
      endrule
   end
   
   
   Vector#(numServers, DRAM_LOCK_Server) ds;
   for (Integer i = 0; i < 2; i = i + 1)
      ds[i] = (interface DRAM_LOCK_Server;
                  interface Put request = toPut(reqs[i]);
                  interface Get response = toGet(resps[i]);
               endinterface);
   
   interface dramServers = ds;
   
   interface DRAM_LOCK_Client dramClient;
      interface Get request = toGet(cmdQ);
      interface Put response = toPut(dataQ);
   endinterface
      
endmodule


           
endpackage

