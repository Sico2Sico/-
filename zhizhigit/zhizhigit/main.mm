#include <iostream>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <time.h>
#include <pthread.h>
#include "threadpool.h"

using namespace std;


void * mytask(void *arg){
	cout << "线程ID="<<(int)pthread_self()<<"正在执行"<< *(int*)arg<<endl;
	delete (int*)arg;
	return  (void* ) 0; 
	}


int main(void){
	threadpool_t pool;
	threadpool_init(&pool , 3);
	
	size_t i;
	for(i=0 ; i<10 ; i++){
		int *arg = new int ;
		*arg = i;
		threadpool_add_task( &pool , mytask , arg );   //添加任务
		}
	sleep(6);
	threadpool_destroy(&pool);	          //销毁线程池
	return 0;
	}
