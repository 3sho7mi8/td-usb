// tdtimer-macos.c - macOS timer implementation using simple approach

#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <pthread.h>
#include "../tdtimer.h"

static void (*callback_func)(void *) = NULL;
static void *callback_param = NULL;
static int timer_interval = 0;
static int timer_running = 0;
static pthread_t timer_thread;

static void* timer_worker(void* arg) {
    while (timer_running) {
        usleep(timer_interval * 1000); // Convert ms to microseconds
        if (timer_running && callback_func) {
            callback_func(callback_param);
        }
    }
    return NULL;
}

int TdTimer_Start(void pCallback(void *), void *pParam, int interval)
{
    if (timer_running) {
        TdTimer_Stop();
    }
    
    callback_func = pCallback;
    callback_param = pParam;
    timer_interval = interval;
    timer_running = 1;
    
    if (pthread_create(&timer_thread, NULL, timer_worker, NULL) != 0) {
        timer_running = 0;
        return -1;
    }
    
    return 0;
}

int TdTimer_Stop()
{
    if (timer_running) {
        timer_running = 0;
        pthread_join(timer_thread, NULL);
    }
    callback_func = NULL;
    callback_param = NULL;
    return 0;
}