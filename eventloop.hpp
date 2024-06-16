#include "types.h"

class EventHandlerInterface {
public:
	virtual int handleEvent() = 0;

};

template <typename T_TYPE, int T_SIZE>
class Queue {

	T_TYPE buf[T_SIZE];
	int wptr = 0;
	int rptr = 0;
	int count = 0;

	static void incrPtr(int *ptr) {
		int newptr = *ptr;
		if (newptr == T_SIZE)
			newptr = 0;
		*ptr = newptr;
	}

public:
	bool isEmpty() {
		return (count == 0 ? true : false); 
	}

	bool isFull() {
		return (count == T_SIZE ? true : false);
	}

	int push(const T_TYPE &elem) {
		if (isFull())
			return -1;
		buf[wptr] = elem;
		incrPtr(&wptr);
		count++;
		
	}

	int pop(T_TYPE *out) {
		if (isEmpty())
			return -1;
		*out = buf[rptr];
		incrPtr(&wptr);
		count--;
	}

};

template <int T_NUM_BITS>
class BitSet {

	uint8_t data[(T_NUM_BITS-1)/8 + 1] = {0};

public:
	void set(int pos) {
		this->data[pos >> 3] |= (1 << pos);
	}

	void clear(int pos) {
		this->data[pos >> 3] &= ~(1 << pos);
	}

	bool contains(int pos) {
		return (this->data[pos >> 3] & (1 << pos)) ? true : false;
	}

	void clearAll() {
		for (auto &octet : this->data) {
			octet = 0;
		}
	}

	bool isEmpty() {
		for (auto octet : this->data) {
			if (octet)
				return false;
		}
		return true;
	}

	int count() {
		int cnt = 0;
		for (auto octet : this->data) {
			while (octet > 0) {
				if (octet & 1)
					cnt++;
				octet >>= 1;
			}
		}
		return cnt;
	}
};

struct Event {
	int id;
	EventHandlerInterface *handler;
};

template <int T_NUM_HANDLERS, int T_QUEUE_SIZE>
class EventLoop {
	BitSet<T_NUM_HANDLERS> bitset;
	Queue<Event, T_QUEUE_SIZE> eventQueue;

public:

	int init() { return 0; }

	/* Management */
	int getFreeId() {
		int id = 0;
		for (int i = 0; i < T_NUM_HANDLERS; i++) {
			if (! this->bitset.isSet(i))
				return i;
		}
		return -1;
	}

	int setHandler(int event_id, EventHandlerInterface *handler) {
		this->handlers[event_id] = handler;
	}

	/* Producer side */
	int enqueue(EventHandlerInterface *handler, int event_id=0) {
		Event event = {.id = event_id, .handler = handler};
		eventQueue.push(event);
		return 0;
	}

	/* Consumer side */
	int dispatch() {
		Event event;
		eventQueue.pop(&event);
		event.handler->handleEvent();
		return 0;
	}
	int run() { return 0; }

};
