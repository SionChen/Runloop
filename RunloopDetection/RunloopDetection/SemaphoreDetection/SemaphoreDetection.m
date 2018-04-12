//
//  SemaphoreDetection.m
//  RunloopDetection
//
//  Created by 超级腕电商 on 2018/4/11.
//  Copyright © 2018年 超级腕电商. All rights reserved.
//

#import "SemaphoreDetection.h"

#import <libkern/OSAtomic.h>
#import <execinfo.h>

@implementation SemaphoreDetection{
    /*主线程runloop观察者*/
    CFRunLoopObserverRef _observer;
    /*信号量控制*/
    dispatch_semaphore_t _semaphore;
    /*全局Runloop状态*/
    CFRunLoopActivity _activity;
    /*超出预订卡顿时间的次数*/
    NSInteger _countTime;
    /*堆栈信息*/
    NSMutableArray *_backtrace;
}
+ (instancetype) sharedInstance{
    static SemaphoreDetection * instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SemaphoreDetection alloc] init];
    });
    return instance;
}
-(void)startDetection{
    [self registerObserver];
}
-(void)endDetection{
    if (_observer) {
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
        CFRelease(_observer);
        _observer = NULL;
    }
}

/**
 监听回调

 @param observer 观察者
 @param activity 状态
 @param info - -
 */
void runloopObserverAction(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    /*RunLoop 顺序
     1、进入
     
     2、通知Timer
     3、通知Source
     4、处理Source
     5、如果有 Source1 调转到 11
     6、通知 BeforWaiting
     7、wait
     8、通知afterWaiting
     9、处理timer
     10、处理 dispatch 到 main_queue 的 block
     11、处理 Source1、
     12、进入 2
     
     13、退出
     
     */
    SemaphoreDetection *instrance = [SemaphoreDetection sharedInstance];
    instrance->_activity = activity;
    // 发送信号
    dispatch_semaphore_t semaphore = instrance->_semaphore;
    dispatch_semaphore_signal(semaphore);
}
/**
 两件事 1、监听主线程Runloop
       2、开辟一个线程监听mainRunloop循环延时
 */
-(void)registerObserver{
    //设置Run loop observer的运行环境
    CFRunLoopObserverContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    //创建Run loop observer对象
    //第一个参数用于分配observer对象的内存
    //第二个参数用以设置observer所要关注的事件，详见回调函数myRunLoopObserver中注释
    //第三个参数用于标识该observer是在第一次进入run loop时执行还是每次进入run loop处理时均执行
    //第四个参数用于设置该observer的优先级
    //第五个参数用于设置该observer的回调函数
    //第六个参数用于设置该observer的运行环境

    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &runloopObserverAction, &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    //创建初始信号量为0 的dispatch_semaphore
    _semaphore = dispatch_semaphore_create(0);
    //开辟线程监听延时
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //死循环监听 通过控制信号量 来实现 mainrunloop循环或者超时的时候才会执行
        while (YES) {
            // 累计延迟超过250ms包含--》 （设置连续5次超时50ms认为卡顿(当然也包含了单次超时250ms)）
            //dispatch_semaphore_t 是一个信号量机制，信号量到达、或者 超时会继续向下进行，否则等待，如果超时则返回的结果必定不为0，信号量到达结果为0。信号量为小于等于0的时候会阻塞当前线程
            long semaphoreInt = dispatch_semaphore_wait(self->_semaphore, dispatch_time(DISPATCH_TIME_NOW, 50*NSEC_PER_MSEC));
            
            if (semaphoreInt!=0) {//超时
                /* kCFRunLoopEntry         = (1UL << 0), // 即将进入Loop
                 kCFRunLoopBeforeTimers  = (1UL << 1), // 即将处理 Timer
                 kCFRunLoopBeforeSources = (1UL << 2), // 即将处理 Source
                 kCFRunLoopBeforeWaiting = (1UL << 5), // 即将进入休眠
                 kCFRunLoopAfterWaiting  = (1UL << 6), // 刚从休眠中唤醒
                 kCFRunLoopExit          = (1UL << 7), // 即将退出Loop*/
                
                if (self->_activity==kCFRunLoopBeforeSources || self->_activity==kCFRunLoopAfterWaiting)
                {
                    if (++self->_countTime < 5)
                        continue;
                    [self logStack];//记录卡顿堆栈信息
                    NSLog(@"*************lag******************");
                }
            }
            self->_countTime=0;
        }
    });
}

/**
 输出堆栈信息
 */
- (void)logStack{
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    int i;
    _backtrace = [NSMutableArray arrayWithCapacity:frames];
    for ( i = 0 ; i < frames ; i++ ){
        [_backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
}
@end
