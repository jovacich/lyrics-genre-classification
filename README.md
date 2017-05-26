# lyrics-genre-classification
Classify artist genres using lyrics! Inspired by http://www.degeneratestate.org/posts/2016/Apr/20/heavy-metal-and-natural-language-processing-part-1/.

Uses files available from the Million Song Dataset (https://labrosa.ee.columbia.edu/millionsong/pages/getting-dataset, 1 and 2 under additional files), musiXmatch lyrics set (https://labrosa.ee.columbia.edu/millionsong/musixmatch, train and test data), and Tagtraum genre set (http://www.tagtraum.com/msd_genre_datasets.html, CD2).

Artist genre is defined as the genre the artist has the most songs in (with rock weighted 2/3, because I think the Tagtarum system slightly biases toward rock). Lyrics are in (stemmed) bag-of-words format, with word counts summed up across songs for ech artist.

The current best model that I'm aware of is L2 regularized logistic regression, which has a test misclassification rate of 0.469377. Not amazing, but it slightly outperforms my goal of 50% accuracy.

lyrics.py creates a .csv of lyrics from the sparse format given by musiXmatch. The .csv is huge and sparse; I imagine there's a better way to deal with them in R but the .csv works well enough.

consolidation.R gathers the data, runs the model and creates a confusion matrix
network.R creates a nifty genre network diagram. This is currently just based off frequencies (not the model); I'd like to make a network plot based on genre misclassification.
considerations.R contains a few text processing techniques that I tried, but which only hindered model accuracy.

I'd like to add code to produce a matrix of most powerful predictive words for each genre; I've done this by hand and the result is fairly amusing.
