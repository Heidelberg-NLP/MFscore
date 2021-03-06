from data_helpers import readf
import sys
import argparse
from log_helper import get_logger
from sent_scorers import ScorerFactory
import logging

logger = logging.getLogger(__name__)

def build_arg_parser():

    parser = argparse.ArgumentParser(
            description='LM assessment')

    parser.add_argument('-text_file_path'
            , type=str
            , help='file path to text')

    parser.add_argument('-out_file_path'
            , type=str
            , default="tmp/out.gpt2_form_scores"
            , help='file path to text')
    
    parser.add_argument('-lm_uri'
            , type=str
            , default="gpt2"
            , choices=["bert-large-cased", "gpt2"]
	    , nargs = '?'
            , help='file path to text')
    
    parser.add_argument('-log_level'
            , type=int
            , nargs='?'
            , default=10
            , choices=list(range(0,60,10))
            , help='logging level (int), see\
                    https://docs.python.org/3/library/logging.html#logging-levels')

    return parser

if __name__ == "__main__":
    args = build_arg_parser().parse_args()
    logger = get_logger("LMscoreLogger", args.log_level)

    clean_sents_fp = args.text_file_path
    lines = readf(clean_sents_fp).split("\n")
    out = []

    logger.info("loading LM ({}) and scoring {}".format(args.lm_uri, args.text_file_path))
    
    scorer = ScorerFactory().get_scorer(args.lm_uri) 
    
    out = scorer.score_sents(lines)
    out = [str(x) for x in out] 
    
    with open(args.out_file_path, "w") as f:
        f.write("\n".join(out))
    
    logger.info("finished, output written to {}".format(args.out_file_path))
