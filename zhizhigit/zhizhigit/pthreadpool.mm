#include <iostream>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <time.h>
#include <pthread.h>
#include "threadpool.h"

using namespace std;

void* thread_routine(void* arg){
	struct timespec abstime;
	int timeout;
	cout << "线程ID"<<(int)pthread_self()<<"启动"<< endl;
	threadpool_t *pool = (threadpool_t *)arg;
	while(1){
		timeout = 0;
		condition_lock(&pool->ready);
		pool ->idle++;
		//等待队列有任务到来 或者 销毁消息
		while((pool->first == NULL)&& (!(pool->quit))){
			cout << "线程ID"<<(int)pthread_self()<<"等待中"<< endl;
			//condition_wait(&pool->ready);
			clock_gettime(CLOCK_REALTIME , &abstime);
			abstime.tv_sec += 2;
			int status = condition_timedwait(&pool->ready , &abstime);
			if(status == ETIMEDOUT){
				cout << "线程ID"<<(int)pthread_self()<<"等待超时"<< endl;
				timeout = 1;
				break ;
				}
			}
		//等待到条件 ，处于工作状态	
		pool->idle--;
		if(pool->first != NULL ){
			task_t *t = pool->first;
			pool->first = t->next;
			//执行任务需要一定时间 ，所以需要先解锁 
			condition_nulock(&pool->ready);
			t->run(t->arg);       //线程函数消费开始执行 
			delete t;			 //删除任务结构体	
			condition_lock(&pool->ready);
			}
			//等待到销毁
		if((pool->quit) && (pool->first == NULL)){
			pool->counter--;
			if(pool->counter == 0){
				condition_signal(&pool->ready);
				}
			condition_nulock(&pool->ready);
			break ;
			}
		if(timeout && (pool->first == NULL)){
			pool->counter--;
			condition_nulock(&pool->ready);
			break ;
			}		
		condition_unlock(&pool->ready);
		}
		cout << "线程ID"<<(int)pthread_self()<< "销毁"<< endl;
		return (void*) 0;	
	}



// 线程池的初始化
void pthreadpool_init(threadpool_t * pool , int threads){
	condition_init(& pool ->ready);
	pool->first = NULL;
	pool->last = NULL ;
	pool->counter = 0;
	pool->idle = 0;
	pool->max_threads = threads;
	pool->quit = 0;
	}

//添加任务	
void pthreadpool_add_task(threadpool_t * pool , void*(*run)(void* arg), void* arg){
	//void *(*run)(void* arg); // 任务回调函数
	//void *arg;				// 回调函数参数		
	//struct task *next ;
	
	task_t *newtask = new struct task ;
	newtask-> run = run ;
	newtask-> arg = arg;
	newtask-> next= NULL ;
	
    if(pool->first == NULL ){
		pool->first = newtask;
        pool->last = newtask;
        }
    else{
        pool->last-next = newtask;
        pool->last = newtask->next;     //添加后尾指针位置发生改变  后移一位
         }
        //如果有等待线程就唤醒 ，执行其中一
	if(pool->idle >0 ){
		condition_signal(&pool->ready);
	}else if(pool->counter < pool->max_threads){
		//没有线程等待 ，并且当前线程数不操过最大线程 ，创建新线程
		pthread_t tid;
		pthread_create(&tid, NULL ,thread_routine , pool);
		pool->counter++;	
		}
	}

//销毁线程池
void threadpool_destroy(threadpool_t * pool){
	if(pool->quit)
		return ;
	condition_lock(&pool->ready);
	pool->quit = 1;
	if(pool->counter > 0){
		if(pool->idle >0){
			condition_broadcast(&pool->ready);   //向等待线程发起广播
			while(pool->counter >0){
				condition_wait(&pool->ready);    
				}
			}
		}
	condition_unlock(&pool->ready);
	condition_destroy(&pool->ready);            //销毁条件变量             
	
	}
