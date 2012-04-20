.SECONDARY:

##########
# Error category frequency vector generation
##########

##### Shortcut variables #####

CHECKLEN=bash $(HOME)/bin/checklen.sh $*.hfact $@
HYP_TGT_LANG=$(shell basename $* | cut -d . -f 2 | cut -d - -f 2)

##### Addicter #####

## Alignment between factored reference and hypothesis translations
%.ali: %.hfact %.rfact
	$(ADDICTER_PATH)/align-greedy.pl $*.rfact $*.hfact > $@
	@$(CHECKLEN)

## Addicter's translation error analysis
%.add-err: %.ali %.hfact %.sfact %.rfact
	$(ADDICTER_PATH)/finderrs.pl $*.sfact $*.hfact $*.rfact $*.ali > $@

## Addicter's error category per PoS frequency vector
%.add-freqvec: %.add-err
	cat $< | perl $(HOME)/bin/addposscores.pl $(HOME)/possets/$(HYP_TGT_LANG).dat > $@
	@$(CHECKLEN)

##### Hjerson #####

HJFACT_CHECKLEN=bash $(HOME)/bin/checklen.sh $< $@

## Surface forms in a separate file for Hjerson
%-surf: %
	cat $< | perl $(HOME)/bin/exfact.pl 0 > $@
	@$(HJFACT_CHECKLEN)

## Lemmas in a separate file for Hjerson
%-lem: %
	cat $< | perl $(HOME)/bin/exfact.pl 2 > $@
	@$(HJFACT_CHECKLEN)

## Hjerson's translation error analysis
%.hj-err: %.hfact-surf %.hfact-lem %.rfact-surf %.rfact-lem
	python $(HJERSON_PATH)/hjerson.py -R $*.rfact-surf -B $*.rfact-lem -H $*.hfact-surf -b $*.hfact-lem -c $@

## Hjerson's error category per PoS frequency vector
%.hj-freqvec: %.hj-err %.hfact
	perl $(HOME)/bin/hjposscores.pl $*.hj-err $*.hfact $*.rfact $(HOME)/possets/$(HYP_TGT_LANG).dat > $@
	@$(CHECKLEN)

##### Final frequency vectors #####
%.freqvec: %.add-freqvec %.hj-freqvec
	paste -d , $^ > $@
	@$(CHECKLEN)

checkdir:
ifeq ($(DIR),)
	@echo "to build all files, please specify the directory (DIR) of the files"
	@exit 1
endif

all: checkdir $(patsubst %.hfact,%.freqvec,$(wildcard $(DIR)/*.hfact))

.PHONY: all
