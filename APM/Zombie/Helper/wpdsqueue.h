#ifndef __LIBWPDS_QUEUE_H__
#define __LIBWPDS_QUEUE_H__

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

/*
 * 用数组模拟循环队列
 * WPDSQueue is a thread-safe queue that has no limitation on the number of
 * threads that can call wp_ds_queue_put and wp_ds_queue_get simultaneously.
 * That is, it supports a multiple producer and multiple consumer model.
 */

/* WPDSQueue implements a thread-safe queue using a fairly standard
 * circular buffer. */
struct WPDSQueue;

/* Allocates a new WPDSQueue with a buffer size of the capacity given. */
struct WPDSQueue *
wp_ds_queue_create(uint32_t buffer_capacity);

/* Frees all data used to create a WPDSQueue. It should only be called after
 * a call to wp_ds_queue_close to make sure all 'gets' are terminated before
 * destroying mutexes/condition variables.
 *
 * Note that the data inside the buffer is not freed. */
void
wp_ds_queue_free(struct WPDSQueue *queue);

/* Returns the current length (number of items) in the queue. */
int
wp_ds_queue_length(struct WPDSQueue *queue);

/* Returns the capacity of the queue. This is always equivalent to the
 * size of the initial buffer capacity. */
int
wp_ds_queue_capacity(struct WPDSQueue *queue);

/* Closes a queue. A closed queue cannot add any new values.
 *
 * When a queue is closed, an empty queue will always be empty.
 * Therefore, `wp_ds_queue_get` will return NULL and not block when
 * the queue is empty. Therefore, one can traverse the items in a queue
 * in a thread-safe manner with something like:
 *
 *  void *queue_item;
 *  while (NULL != (queue_item = wp_ds_queue_get(queue)))
 *      do_something_with(queue_item);
 */
void
wp_ds_queue_close(struct WPDSQueue *queue);

/* Adds new values to a queue (or "sends values to a consumer").
 * `wp_ds_queue_put` cannot be called with a queue that has been closed. If
 * it is, an assertion error will occur. 
 * If the queue is full, `wp_ds_queue_put` will block until it is not full,
 * in which case the value will be added to the queue. */
void
wp_ds_queue_put(struct WPDSQueue *queue, void *item);

/* Reads new values from a queue (or "receives values from a producer").
 * `wp_ds_queue_get` will block if the queue is empty until a new value has been
 * added to the queue with `wp_ds_queue_put`. In which case, `wp_ds_queue_get` will
 * return the next item in the queue.
 * `wp_ds_queue_get` can be safely called on a queue that has been closed (indeed,
 * this is probably necessary). If the queue is closed and not empty, the next
 * item in the queue is returned. If the queue is closed and empty, it will
 * always be empty, and therefore NULL will be returned immediately. */
void *
wp_ds_queue_get(struct WPDSQueue *queue);

/* Adds new values to a queue (or "sends values to a consumer").
* `wp_ds_queue_put` cannot be called with a queue that has been closed. If
* it is, an assertion error will occur.
* If the queue is full, `wp_ds_queue_put` will pop the first item, and return the item,
* in which case the value will be added to the queue. */
void *
wp_ds_queue_put_pop_first_item_if_need(struct WPDSQueue *queue, void *item);

/*
 *Reads new values from a queue (or "receives values from a producer").
 *return NULL immediately if the queue is empty
 */
void*
wp_ds_queue_try_get(struct WPDSQueue *queue);
    
#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif
