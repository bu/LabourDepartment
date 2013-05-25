all:
	coffee -o ./ -b -c src

clean:
	rm -rf factory/*
	rm -rf *.js
	rm -rf log/*
	rm -rf source
	rm -rf task
