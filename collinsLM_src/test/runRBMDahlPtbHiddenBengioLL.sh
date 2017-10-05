#! /bin/bash

OMP_NUM_THREADS=4 ./neuralLMHiddenBengioLL --embedding_dimension 100 --n_vocab 10000 --train_file ptb.words.all.formatted.3grams.train.1004000 --ngram_size 3 --unigram_probs_file ptb.words.all.formatted.unigram.probs --minibatch_size 1000 --n_hidden 60  --learning_rate 0.01 --num_epochs 100 --words_file ptb.words.all.formatted.words.lst --embeddings_prefix embeddings.cpp.ptb-all.test --use_momentum 0 --validation_file ptb.words.all.formatted.validation --n_threads 4 --num_noise_samples 100 --L2_reg 0.0000 --normalization_init 10 

