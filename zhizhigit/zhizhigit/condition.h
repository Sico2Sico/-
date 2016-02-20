#ifndef _CONDITION_H_
#define _CONDITION_H_

#include<pthread.h>
typedef struct condition{
	pthread_mutex_t pmutex;
	pthread_cond_t pcond;
	}condition_t;
int condition_init(condition_t * cond);   //初始化
int condition_lock(condition_t * cond); //加锁
int condition_unlock(condition_t * cond); //解锁
int condition_wait(condition_t* cond);  //等待事件的调用
int condition_timedwait(condition_t * cond , const struct timespec * abstime); // 超时处理
int condition_signal(condition_t * cond);        //向等待线程发起通知
int condition_broadcast(condition_t * cond);	//向等待线程发起广播	
int condition_destroy(condition_t *cond);		//销毁条件变量




#endif
