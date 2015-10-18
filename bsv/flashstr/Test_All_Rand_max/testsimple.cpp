
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <time.h>

#include <math.h>
#include <pthread.h>
#include <string.h>
#include <vector>

#include "SimpleIndicationWrapper.h"
#include "SimpleRequestProxy.h"
#include "GeneratedTypes.h"

#include <sys/time.h>

//#include "../jenkins_sw/jenkins_hash.h";

//uint32_t dumpLimit;
uint64_t* rdArray;
uint32_t burstCnt = 0;
uint32_t burstLimit;

timeval t1, t2;
double elapsedTime, sum_t_set=0, sum_t_get=0;

pthread_mutex_t mu;
pthread_cond_t rdAck, cond;

uint64_t rdAddr;

class SimpleIndication : public SimpleIndicationWrapper
{  
public:

  uint32_t idCnt;
  virtual void getVal(uint64_t a, uint32_t tag){
    pthread_mutex_lock(&mu);
    fprintf(stderr, "Indication Got: burstCnt = %d, burstLimit = %d, data = %08lx, tag = %d\n", burstCnt, burstLimit, a, tag);
    rdArray[burstCnt++] = a;


    if ( (idCnt&((1<<7)-1)) != tag) {
      fprintf(stderr, "Error:: reqId doesn't match\n");
      exit(0);
    }
    //
    if (burstCnt == burstLimit){
      idCnt++;
      gettimeofday(&t2, NULL);
      elapsedTime = (t2.tv_sec - t1.tv_sec) * 1000.0;      // sec to ms
      elapsedTime += (t2.tv_usec - t1.tv_usec) / 1000.0;   // us to ms
      printf("Main:: Done executing read in %lf millisecs\n", elapsedTime );
      //exit(0);
      burstCnt = 0;
      pthread_cond_broadcast(&cond);
    //incr_cnt();
      
    }
    pthread_mutex_unlock(&mu);
  }

  virtual void wrAck(uint64_t v){
    pthread_mutex_lock(&mu);
    rdAddr = v;
    printf("Main:: Received wrAck addr = %ld\n", v );
    //pthread_cond_broadcast(&rdAck);
    pthread_cond_signal(&rdAck);
    pthread_mutex_unlock(&mu);
  }
  
  SimpleIndication(unsigned int id) : SimpleIndicationWrapper(id), idCnt(0){}
};

int main(int argc, const char **argv)
{
  SimpleIndication *indication = new SimpleIndication(IfcNames_SimpleIndication);
  SimpleRequestProxy *device = new SimpleRequestProxy(IfcNames_SimpleRequest);
  
  pthread_t tid;
  fprintf(stderr, "Main::creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
    fprintf(stderr, "Main::error creating exec thread\n");
    exit(1);
  }
  pthread_mutex_init(&mu, NULL);
  pthread_cond_init(&rdAck, NULL);
  pthread_cond_init(&cond, NULL);
  sleep(1);

  srand(time(NULL));
  //dumpLimit = 72;
  //char key[9] = "deadbeef";
  uint64_t data = 1;
  int numBytes;// = rand()%1000;
  int addr;// = rand()%128;

  std::vector<uint64_t> wrOffsetVec;
  std::vector<uint64_t> sizeVec;
  std::vector<uint64_t> addrVec;


  int maxSz = (1 << 20)*3;
  char* dataBuf = new char[maxSz+(1<<20)];
 
  addr = 0;

  int pageCnt = 0;
  int pageSize = 1 << 13;
  do {

    //numBytes = rand()%1000+1;
    //numBytes = rand()%(2^20)+1;
    numBytes = rand()%1048576+1;
    //numBytes = pageSize * 1.5;
    //numBytes = pageSize;

    // if (pageCnt + numBytes >= pageSize){
    //   numBytes = pageSize - pageCnt;
    //   pageCnt = 0;
    // }
    // else{
    //   pageCnt+=numBytes;
    // } 
                                    

    int loopCnt = (int)ceil(numBytes/8.0);
    //burstLimit = loopCnt;
    
    uint64_t* wrArray = new uint64_t[loopCnt];
  
          
    fprintf(stderr, "Write Request: addr = %d, numBytes = %d, loopCnt = %d\n", addr, numBytes, loopCnt);
    
  
    gettimeofday(&t1, NULL);
    device->writeReq(numBytes);
    pthread_mutex_lock(&mu);
    pthread_cond_wait(&rdAck,&mu);
    pthread_mutex_unlock(&mu);

    for ( int i = 0; i < loopCnt; i++){
      data       = rand();
      data       = data << 32;
      data       = data | rand();
      // data     = i;
      device->writeVal(data);
      wrArray[i] = data;
    }
    gettimeofday(&t2, NULL);
    elapsedTime = (t2.tv_sec - t1.tv_sec) * 1000.0; // sec to ms
    elapsedTime += (t2.tv_usec - t1.tv_usec) / 1000.0; // us to ms

    // pthread_mutex_lock(&mu);
    // pthread_cond_wait(&rdAck,&mu);
    // pthread_mutex_unlock(&mu);
    printf("Write Request Cleanup, bufAddr = %d, rdAddr = %d", addr, rdAddr);
    memcpy(dataBuf+addr, wrArray, numBytes);
    addrVec.push_back(rdAddr);
    wrOffsetVec.push_back(addr);
    sizeVec.push_back(numBytes);

    printf("Main:: free wrArray");
    free(wrArray);
    
    printf("Main:: Done executing write in %lf millisecs\n", elapsedTime );
    fflush(stdout);
    gettimeofday(&t1, NULL);

    addr = addr + numBytes;
  } while ( addr < maxSz );

  for ( int j = 0; j < addrVec.size(); j++ ){
    int i = rand()%addrVec.size();
    
    rdAddr = addrVec[i];
    int wrOffset = wrOffsetVec[i];
    numBytes = sizeVec[i];
    device->readReq(rdAddr,numBytes,j);
    int loopCnt = (int)ceil(numBytes/8.0);
    rdArray = new uint64_t[loopCnt];
    burstLimit = loopCnt;
    fprintf(stderr, "Read Request: addr = %d, numBytes = %d, loopCnt = %d\n", rdAddr, numBytes, loopCnt);
    
    pthread_mutex_lock(&mu);
    pthread_cond_wait(&cond,&mu);
    pthread_mutex_unlock(&mu);
    /*gettimeofday(&t2, NULL);
      elapsedTime = (t2.tv_sec - t1.tv_sec) * 1000.0; // sec to ms
      elapsedTime += (t2.tv_usec - t1.tv_usec) / 1000.0; // us to ms
      printf("Main:: Done executing read in %lf millisecs\n", elapsedTime );
    */
    if (memcmp(dataBuf+wrOffset, rdArray, numBytes) == 0){
      fprintf(stderr, "Main::Done, Pass\n");
    } else {
      fprintf(stderr, "Main::Done, Fail\n");
      uint64_t* wrArray = (uint64_t*)(dataBuf+rdAddr);
      for ( int j = 0; j < (int)ceil(numBytes/8.0); j++ ){
        printf("Main:: wrArray[%d] = %lx, rdArray[%d] = %lx match = %d\n", j,wrArray[j], j,rdArray[j], wrArray[j] != rdArray[j]);
      }
      exit(0);
    }
    fflush(stdout);
  }
  /*
    fprintf(stderr, "Main::about to go to sleep\n"); 
    while(true){};
  while(true){
    pthread_mutex_lock(&mu);
    if (burstCnt == loopCnt) {
      gettimeofday(&t2, NULL);
      elapsedTime = (t2.tv_sec - t1.tv_sec) * 1000.0;      // sec to ms
      elapsedTime += (t2.tv_usec - t1.tv_usec) / 1000.0;   // us to ms
      printf("Main:: Done executing read in %lf millisecs\n", elapsedTime );

      if (memcmp(wrArray, rdArray, numBytes) == 0){
        fprintf(stderr, "Main::Done, Pass\n");
      } else {
        fprintf(stderr, "Main::Done, Fail\n");
      }
 
      exit(0);
    }
    pthread_mutex_unlock(&mu);
  }
  */
}
