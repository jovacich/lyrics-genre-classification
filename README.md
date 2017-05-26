# lyrics-genre-classification
Classify artist genres using lyrics! 

Uses files available from the Million Song Dataset (https://labrosa.ee.columbia.edu/millionsong/pages/getting-dataset, 1 and 2 under additional files), musiXmatch lyrics set (https://labrosa.ee.columbia.edu/millionsong/musixmatch, train and test data as well as topWords), and Tagtraum genre set (http://www.tagtraum.com/msd_genre_datasets.html, CD2).

Artist genre is defined as the genre the artist has the most songs in (with rock weighted 2/3, because I think the Tagtarum system slightly biases toward rock). Lyrics are in (stemmed) bag-of-words format, with word counts summed up across songs.

The current best model that I'm aware of is L2 regularized logistic regression, which has a test misclassification rate of 0.469377. Not amazing, but it slightly outperforms my goal of 50% accuracy.
