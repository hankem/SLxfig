# -*- sh -*-

SL_FILES = simple.sl subplot.sl color.sl histplt.sl image.sl errbar.sl 
PNG_FILES = simple.png subplot.png color.png histplt.png image.png errbar.png 

png: $(PNG_FILES)
%.png: %.sl
	slsh $<
clean:
	/bin/rm -f $(PNG_FILES) *.fig *~
	/bin/rm -rf slxfigtmp


