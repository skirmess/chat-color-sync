
.PHONY: clean tag release

VERSION=3

clean:
	rm -f *~

tag: clean
	cvs tag ChatColorSync-$(VERSION)

release: clean
	CHANGES=`svn st`; if [ -n "$$CHANGES" ]; then echo "### uncommited changes";  false; fi
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
