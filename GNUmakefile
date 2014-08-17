
.PHONY: clean tag release

VERSION=12

clean:
	rm -f *~
	rm -f ChatColorSync-*.zip

release: clean
	(								\
		find ChatColorSync					\
				-name '.*.swp' -prune -o		\
				-print					\
		| zip -@ ChatColorSync-$(VERSION).zip;			\
	)	
