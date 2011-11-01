SUBDIRS = \
  3d \
  draw \
  pict \
  plot \
  polyline

all clean distclean:
	@for subdir in $(SUBDIRS); do \
	  make -C $$subdir $@; \
	done
