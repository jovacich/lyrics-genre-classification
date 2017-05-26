#try to remove stopwords
lyrics2 = lyrics
lyrics2 = lyrics2[,-(stopWordsIndex+6)]

trainDat = lyrics2[train,]

#randomforest.. results are very poor
lyrics.forest = randomForest(trainDat[,7:5006],trainDat[,2],ntree = 1,mtry = 50)
pred = predict(lyrics.forest,lyrics2[-train,5:5006], ntrees=1)
mse = rep(1,5958)
mse[which(pred[1]==lyrics2[-train,2])]=0
mean(mse)
varImpPlot(lyrics.forest)
plot(lyrics.forest)
plot(lyrics.forest, legend("topright", legend=unique(lyrics2$Genre), col=unique(lyrics2$Genre), pch=19))

#weight by tf-idf
lyrics2 = lyrics
words = as.DocumentTermMatrix(lyrics2[,7:5006],weighting=weightTfIdf)
words = as.matrix(words)
words = as.data.frame(words)
lyrics2[,7:5006] = words
lyrics2[,5:5006] = scale(lyrics2[,5:5006])
