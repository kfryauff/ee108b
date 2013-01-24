default:
	spim -mapped_io -st 1024 -file pong.s | ./pong_display.py
    
debug:
	spim -mapped_io -st 1024 -file pong.s | ./pong_display.py -d

tofile:
	rm -f pong_out.txt
	spim -mapped_io -st 1024 -file pong.s > pong_out.txt

fromfile:
	cat pong_out.txt | ./pong_display.py
