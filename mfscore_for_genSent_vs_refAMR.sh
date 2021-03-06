#!/usr/bin/env bash

CLEANER_URI="basic" #options: basic
LM_URI="gpt2" #options: gpt2, gpt2-medium, gpt2-large, gpt2-xl, distilgpt2, bert-base-cased, roberta-large.... etc
PARSER_URI="t5-amrlib" #options: t5-amrlib, gsii-amrlib (cai & lam 2020 without recat)

PATH_GEN=$(cd "$(dirname "$1")"; pwd -P)/$(basename "$1")
PATH_AMR_REF=$(cd "$(dirname "$2")"; pwd -P)/$(basename "$2")

FILE_GEN=$(basename $PATH_GEN)
FILE_AMR=$(basename $PATH_AMR_REF)

LOGLEVEL=20

cd src

python clean.py \
    -input_file_path $PATH_GEN \
    -input_file_type sent-per-line \
    -cleaner_uri $CLEANER_URI \
    -out_file_path tmp/$FILE_GEN.clean \
    -acronym_file_paths ../data/dict/country_adjectivals.txt \
        ../data/dict/acronyms.txt \
    -log_level $LOGLEVEL

python clean.py \
    -input_file_path $PATH_AMR_REF \
    -input_file_type amr-bank \
    -cleaner_uri CLEANER_URI \
    -out_file_path tmp/$FILE_AMR-sents.clean \
    -acronym_file_paths ../data/dict/country_adjectivals.txt \
        ../data/dict/acronyms.txt \
    -log_level $LOGLEVEL

python parse.py -text_file_path tmp/$FILE_GEN.clean \
    -out_file_path tmp/$FILE_GEN.clean.parsed \
    -parser_uri $PARSER_URI \
    -log_level $LOGLEVEL

python score_form.py \
    -text_file_path tmp/$FILE_GEN.clean \
    -out_file_path tmp/$FILE_GEN.clean.lm_score \
    -lm_uri $LM_URI \
    -log_level $LOGLEVEL

python score_form.py \
    -text_file_path tmp/$FILE_AMR-sents.clean \
    -out_file_path tmp/$FILE_AMR-sents.clean.lm_score \
    -lm_uri $LM_URI \
    -log_level $LOGLEVEL

python compute_acceptable_ratio.py \
    -score_file_path tmp/$FILE_GEN.clean.lm_score \
    -ref_score_file_path tmp/$FILE_AMR-sents.clean.lm_score \
    -out_file_path tmp/$FILE_GEN-vs-$FILE_AMR-sents.lm_score.normalized \
    -tolerance 0.05 \
    -log_level $LOGLEVEL

cd ..

cd amr-metric-suite/py3-Smatch-and-S2match/smatch/

python s2match.py -f ../../../src/tmp/$FILE_GEN.clean.parsed $PATH_AMR_REF \
    -vectors ../../vectors/glove.6B.100d.txt \
    > ../../../src/tmp/$FILE_GEN-vs-$FILE_AMR.s2match

cd ../../../src

python mfscore.py \
    -meaning_score_file_path tmp/$FILE_GEN-vs-$FILE_AMR.s2match \
    -form_score_file_path tmp/$FILE_GEN-vs-$FILE_AMR-sents.lm_score.normalized \
    -log_level $LOGLEVEL 
