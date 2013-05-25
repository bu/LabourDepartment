all:
	coffee -o ./ -b -c src

clean:
	rm -rf *.js
	rm -rf factory
	rm -rf log
	rm -rf source
	rm -rf task
	rm -rf notify
