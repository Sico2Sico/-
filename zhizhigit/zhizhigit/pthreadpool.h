#ifndef _PTHREADPOOL_H_
#define _PTHREADPOOL_H_

#include "condition.h"

//任务结构体，将任务放入队列由线程池中的线程来执行
typedef struct task {
	void *(*run)(void* arg); // 任务回调函数
	void *arg;				// 回调函数参数		
	struct task *next ;
	}task_t;

//线程池结构体
typedef struct threadpool{
	condition_t ready ; //任务准备或者线程池销毁通知
	task_t *first ;     
	task_t *last;
	int counter ;       //当前线程数
	int idle ;			// 等待任务的线程数	
	int max_threads;	// 最大线程数	
	int quit ;			// 置1 销毁线程池
	}threadpool_t;

//初始化线程池 
void threadpool_init(threadpool_t * pool , int threads);
//往线程池中添加任务
void threadpool_add_task(threadpool_t* pool , void* (*run)(void *arg), void * arg);
//销毁线程池
void threadpool_destroy(threadpool_t * pool );














#endif
