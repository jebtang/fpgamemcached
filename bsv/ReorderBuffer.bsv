import Cntrs::*;
import FIFOVector::*;
import FIFO::*;
import GetPut::*;
import ControllerTypes::*;
import Connectable::*;
import ClientServer::*;

interface ReorderBuffer;
   method Action enqReq(TagT tag, Bit#(21) nBytes);
   interface Put#(Tuple2#(Bit#(128), Bool)) inPipe;
   method Action deqReq(TagT tag, Bit#(21) nBytes);
   interface Get#(Tuple2#(Bit#(128), Bool)) outPipe;
endinterface

(*synthesize*)
module mkReorderBuffer(ReorderBuffer);
   FIFOVector#(128, Bit#(7), 128) sndQIds <- mkBRAMFIFOVector();
   FIFOVector#(128, Tuple2#(Bit#(128),Bool), 16) fifos <- mkBRAMFIFOVector();
   FIFO#(Bit#(7)) freeSndQId <- mkSizedFIFO(128);

   Reg#(Bit#(7)) initCnt <- mkReg(0);
   Reg#(Bool) initialized <- mkReg(False);
   
   FIFO#(Tuple2#(TagT, Bit#(21))) enqReqQ  <- mkFIFO();
   //Count#(Bit#(8)) freeQCnt <- mkCount(128);
   
   
   rule init if (!initialized);
      freeSndQId.enq(initCnt);
      initCnt <= initCnt + 1;
      if ( initCnt == -1 ) begin
         initialized <= True;
      end
   endrule
 
   Reg#(Bit#(21)) byteCnt_wr <- mkReg(0);
   FIFO#(Tuple2#(Bit#(128), Bool)) inDtaQ <- mkFIFO();
   
   rule doEnqData if ( initialized);
      let d <- toGet(inDtaQ).get();

      let v = enqReqQ.first();
      let tag_req = tpl_1(v);
      let nBytes = tpl_2(v);

      let tag_fifo = freeSndQId.first();
      Bool fifoIdQ_en =  (byteCnt_wr%256 == 240);

      if ( byteCnt_wr%256 == 0 )
         sndQIds.enq(tag_req, tag_fifo); 
      
      fifos.enq(tag_fifo, d);
      
      if (byteCnt_wr +16 >= nBytes) begin
         enqReqQ.deq();
         fifoIdQ_en = True;
         byteCnt_wr <= 0;
      end
      else begin
         byteCnt_wr <= byteCnt_wr + 16;
      end
      $display("%m, doEnqData, byteCnt_wr = %d, fifoIdQ_en = %b", byteCnt_wr, fifoIdQ_en);
      
      if ( fifoIdQ_en) begin
         freeSndQId.deq;
         $display("deq freeSndId tag = %d", tag_fifo);
      end
   endrule
   
   
   Reg#(Bit#(8)) bufCnt <- mkReg(0);
   FIFO#(Tuple2#(TagT, Bit#(21))) deqReqQ <- mkFIFO;
   rule doDeqReq if (initialized);
      let v = deqReqQ.first();
      let tag = tpl_1(v);
      let nBytes = tpl_2(v);
      let nBufs = nBytes/256;
      if ( nBytes%256 != 0) nBufs = nBufs + 1;

      sndQIds.deqServer.request.put(tag);
      if ( extend(bufCnt) + 1 < nBufs ) begin
         bufCnt <= bufCnt + 1;
      end
      else begin
         bufCnt <= 0;
         deqReqQ.deq();
      end
   endrule
   
   FIFO#(Bit#(7)) fifoIdQ <- mkFIFO();
   mkConnection(toPut(fifoIdQ), sndQIds.deqServer.response);
   
   Reg#(Bit#(21)) byteCnt_rd <- mkReg(0);
   FIFO#(Bit#(21)) deqBytesQ <- mkFIFO();
   rule doDeqData if (initialized);
      let nBytes = deqBytesQ.first;

      let tag_fifo = fifoIdQ.first();

      Bool fifoIdQ_en = (byteCnt_rd%256 == 240);
     
      fifos.deqServer.request.put(tag_fifo);
      
      if (byteCnt_rd +16 >= nBytes) begin
         deqBytesQ.deq();
         fifoIdQ_en = True;
         byteCnt_rd <= 0;
      end
      else begin
         byteCnt_rd <= byteCnt_rd + 16;
      end
      
      if ( fifoIdQ_en) begin
         //freeIdQ.deq;
         fifoIdQ.deq();
         freeSndQId.enq(tag_fifo);
      end
   endrule
   
   
   
   method Action enqReq(TagT tag, Bit#(21) nBytes);
      enqReqQ.enq(tuple2(tag, nBytes));
   endmethod
   interface Put inPipe = toPut(inDtaQ);
   method Action deqReq(TagT tag, Bit#(21) nBytes);
      deqReqQ.enq(tuple2(tag, nBytes));
      deqBytesQ.enq(nBytes);
   endmethod
   interface Get outPipe = fifos.deqServer.response;
endmodule

   
