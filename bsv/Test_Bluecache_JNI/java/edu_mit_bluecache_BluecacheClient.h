/* DO NOT EDIT THIS FILE - it is machine generated */
#include <jni.h>
/* Header for class edu_mit_bluecache_BluecacheClient */

#ifndef _Included_edu_mit_bluecache_BluecacheClient
#define _Included_edu_mit_bluecache_BluecacheClient
#ifdef __cplusplus
extern "C" {
#endif
/*
 * Class:     edu_mit_bluecache_BluecacheClient
 * Method:    initBluecache
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_edu_mit_bluecache_BluecacheClient_initBluecache
  (JNIEnv *, jobject);

/*
 * Class:     edu_mit_bluecache_BluecacheClient
 * Method:    sendSet
 * Signature: ([B[BI)Z
 */
JNIEXPORT jboolean JNICALL Java_edu_mit_bluecache_BluecacheClient_sendSet
  (JNIEnv *, jobject, jbyteArray, jbyteArray, jint);

/*
 * Class:     edu_mit_bluecache_BluecacheClient
 * Method:    sendGet
 * Signature: ([BI)[B
 */
JNIEXPORT jbyteArray JNICALL Java_edu_mit_bluecache_BluecacheClient_sendGet
  (JNIEnv *, jobject, jbyteArray, jint);

/*
 * Class:     edu_mit_bluecache_BluecacheClient
 * Method:    sendDelete
 * Signature: ([BI)Z
 */
JNIEXPORT jboolean JNICALL Java_edu_mit_bluecache_BluecacheClient_sendDelete
  (JNIEnv *, jobject, jbyteArray, jint);

/*
 * Class:     edu_mit_bluecache_BluecacheClient
 * Method:    getGetAvgLatency
 * Signature: ()D
 */
JNIEXPORT jdouble JNICALL Java_edu_mit_bluecache_BluecacheClient_getGetAvgLatency
  (JNIEnv *, jobject);

#ifdef __cplusplus
}
#endif
#endif