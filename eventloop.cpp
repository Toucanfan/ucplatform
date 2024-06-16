#include "eventloop.hpp"


int main(void) {
	EventLoop<8, 8> loop;
	loop.dispatch();
	return loop.init();
}
