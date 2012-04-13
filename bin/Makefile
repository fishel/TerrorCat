ADDICTER_PATH := /home/mphi/proj/addicter
HJERSON_PATH := /home/mphi/proj/hjerson
WEKAJAR := /home/mphi/proj/weka/weka.jar

JAVA := java -Xmx5g -cp $(WEKAJAR)

.SECONDARY:

##########
# Error category frequency vector generation
##########

##### Shortcut variables #####

CHECKLEN=bash bin/checklen.sh $*.hfact $@
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
	cat $< | bin/addposscores.pl possets/$(HYP_TGT_LANG).dat > $@
	@$(CHECKLEN)

##### Hjerson #####

HJFACT_CHECKLEN=bash bin/checklen.sh $< $@

## Surface forms in a separate file for Hjerson
%-surf: %
	cat $< | perl bin/exfact.pl 0 > $@
	@$(HJFACT_CHECKLEN)

## Lemmas in a separate file for Hjerson
%-lem: %
	cat $< | perl bin/exfact.pl 2 > $@
	@$(HJFACT_CHECKLEN)

## Hjerson's translation error analysis
%.hj-err: %.hfact-surf %.hfact-lem %.rfact-surf %.rfact-lem
	python $(HJERSON_PATH)/hjerson.py -R $*.rfact-surf -B $*.rfact-lem -H $*.hfact-surf -b $*.hfact-lem -c $@

## Hjerson's error category per PoS frequency vector
%.hj-freqvec: %.hj-err %.hfact
	perl bin/hjposscores.pl $*.hj-err $*.hfact $*.rfact possets/$(HYP_TGT_LANG).dat > $@
	@$(CHECKLEN)

##### Final frequency vectors #####
%.freqvec: %.add-freqvec %.hj-freqvec
	paste -d , $^ > $@
	@$(CHECKLEN)
