SUBDIRS = \
  draw \
  pict \
  plot \
  polyline

png clean distclean:
	@for subdir in $(SUBDIRS); do \
	  make -C $$subdir $@; \
	done
