
.PHONY: clean tag release

VERSION=12

clean:
	rm -f *~

tag: clean
	cvs tag ChatColorSync-$(VERSION)

release: clean
	( cd ..;							\
		rm -f ChatColorSync-$(VERSION).zip;			\
		find ChatColorSync					\
				-name CVS -prune -o			\
				-name .svn -prune -o			\
				-name Makefile -prune -o		\
				-name '.*.swp' -prune -o		\
				-print					\
		| zip -@ ChatColorSync-$(VERSION).zip;			\
	)	
