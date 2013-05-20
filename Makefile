all:
	coffee -o ./ -b -c src

clean:
	rm -rf factory/*
	rm -rf *.js
	rm -rf source
	rm -rf task
