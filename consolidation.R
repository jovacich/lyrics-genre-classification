library(nnet)
library(dplyr)
library(ggplot2)
library(scales)
library(data.table)
library(probsvm)
library(randomForest)
library(lsa)
library(tm)
library(LiblineaR)
library(caret)
##first, identify the dominant genre of each artist based on available song
##genre information. will create a table of artist names and dominant genre
##(artistGenre) by the end.

#get table of artist names, artist ids (artist names)
artist.names <- read.table("unique_artists.txt",sep="\t",quote="",
                            col.names=c("artist.id","artist.mbid",
                                        "track.id","artist.name"))
artist.names[,2:3]=NULL

#get table with tracks ids and artist names (tracks)
tracks <- read.table("unique_tracks.txt",sep="\t",quote="",
                      col.names=c("track.id","song.id","artist.name",
                                  "song.title"),comment.char = "")
tracks[,2]=NULL

#combine tracks and artist names by artist name
tracks <- merge(tracks,artist.names,by="artist.name")

#get table of primary/secondary genre and track id (genres)
genres <- read.table("track_genres.txt",sep="\t",quote="",
          col.names=c("track.id","primary.genre","secondary.genre"),fill=TRUE)

#create barplots for primary and secondary genre
primGenreCount = genres %>% group_by(primary.genre) %>% tally
secGenreCount = genres %>% group_by(secondary.genre) %>% tally
barplot(primGenreCount$n,names=primGenreCount$primary.genre,main = "Primary Genre Counts")
secGenreCount=secGenreCount[-1,]
barplot(secGenreCount$n,names=secGenreCount$secondary.genre, main = "Secondary Genre Count")

#combine genres with tracks by track id
tracks <- merge(tracks,genres,by="track.id")

#create table of primary genre counts for each artist (genreCounts)
genreCounts = with(tracks, table(artist.name,primary.genre))
genreCounts <- as.data.frame.matrix(genreCounts)

#remove artists with no genre data from genreCounts
genreSum = rowSums(genreCounts[,1:15])
genreCounts <- genreCounts[-which(genreSum==0),]

#create table of secondary genre counts for each artist (genreCountsSec)
genreCountsSec = with(tracks, table(artist.name, secondary.genre))
genreCountsSec <-as.data.frame.matrix(genreCountsSec)

#remove artists with no majority genre data from genreCountsSec
genreCountsSec <- genreCountsSec[-which(genreSum==0),]
genreCountsSec[,1]=NULL

#add weighted minority counts to majority counts (genreCountsWeight)
genreCounts = genreCounts + genreCountsSec*(2/3)

#choose genre with highest count for each artist (ties broken at random)
set.seed(1)
genreCounts$maxGenre <- apply(genreCounts[,1:15], 1, which.is.max)
genreCounts$max <- apply(genreCounts[,1:15],1,max)
genreCounts$sum <- apply(genreCounts[,1:15],1,sum)
genreCounts$purity <- genreCounts$max/genreCounts$sum
genreNames=colnames(genreCounts[,1:15])
genreCounts$maxGenre <- genreNames[genreCounts$maxGenre]

#remove artists with purity<50% and <5 songs
genreCounts = genreCounts[which(genreCounts$purity>0.5),]
genreCounts = genreCounts[which(genreCounts$sum>3),]

#create table of count, purity
purity = genreCounts %>% group_by(maxGenre) %>% summarise_at(19,funs(mean(., na.rm=TRUE)))
network = genreCounts %>% group_by(maxGenre) %>% summarise_all(funs(sum(., na.rm=TRUE)))

#create new df with only artist name and dominant genre (artistGenre)
artistGenre <- data.frame(ArtistName = rownames(genreCounts),Genre=genreCounts$maxGenre)

#plot this and realize there's just too much rock in the world
ggplot(data=artistGenre, aes(x=artistGenre$Genre,fill=artistGenre$Genre)) + 
  geom_bar(aes(y=(..count..)/sum(..count..))) + 
  guides(fill=FALSE) + 
  labs(title="Unweighted Genre Percentage",x="Genre",y="Percent") +
  theme(axis.text.y=element_blank(), axis.ticks=element_blank(),
    axis.title.y=element_blank()) + 
  geom_text(aes(y = ((..count..)/sum(..count..)), 
                    label = scales::percent((..count..)/sum(..count..))), 
                stat = "count", vjust = -0.25) +
  scale_y_continuous(labels = percent)

#decrease rock weight
genreCounts$Rock=genreCounts$Rock/3
genreCounts$maxGenre <- apply(genreCounts[1:15], 1, which.is.max)
genreCounts$maxGenre <- genreNames[genreCounts$maxGenre]
artistGenre2 <- data.frame(ArtistName = rownames(genreCounts),
                           Genre=genreCounts$maxGenre)


#PLOT
ggplot(data=artistGenre2, aes(x=artistGenre2$Genre,fill=artistGenre2$Genre)) + 
  geom_bar(aes(y=(..count..)/sum(..count..))) + 
  guides(fill=FALSE) + 
  labs(title="Genre Percentage (Rock weighted 1/3)",x="Genre",y="Percent") +
  theme(axis.text.y=element_blank(), axis.ticks=element_blank(),
        axis.title.y=element_blank()) + 
  geom_text(aes(y = ((..count..)/sum(..count..)), 
                label = scales::percent((..count..)/sum(..count..))), 
            stat = "count", vjust = -0.25) +
  scale_y_continuous(labels = percent)

###############################################
## now create matrix of word counts per artist
#get list of topwords. this is just created from the header of the training lyrics document; i just copy-pasted it into a new document
topWords = strsplit(readLines("topWords.txt"),split=",")
topWords = make.names(topWords[[1]])

#stopwords
stopWords <- readLines("stopWords.txt")
stopWordsIndex = match(stopWords,topWords)
stopWordsIndex = na.omit(stopWordsIndex)
stopWords = topWords[-stopWordsIndex]

#load large sparse matrix of top 5000 word counts per song
lyrics <- fread("/Users/jack/PycharmProjects/Lyrics/output.csv",header=FALSE)

#load corresponding song IDs into lyric matrix
trainIds <- read.table("mxm_dataset_train.txt",comment.char=",")
testIds <- read.table("mxm_dataset_test.txt",comment.char=",")
lyricIds <- rbind(testIds,trainIds)
lyrics$track.id <- lyricIds$V1

#merge with artist data, removing superfluous columns
lyrics <- merge(lyrics,tracks[,1:2],by="track.id")
lyrics$track.id=NULL
lyrics$songCount = 1

#add up word counts by artist
lyrics <- lyrics %>% group_by(artist.name) %>% summarise_each(funs(sum))

#add genre information
lyrics  <- merge(lyrics,artistGenre2,by.x="artist.name",by.y="ArtistName")
lyrics <- lyrics[,c(1,5004,5003,5002,2:5001)]
colnames(lyrics) <- c("ArtistName","Genre", "SongCount", "WordCount", topWords)

#add arbitrary "wordiness" rating
lyrics$Wordiness = lyrics$WordCount / lyrics$SongCount

#list of stemmed curse words found in top 5000
curse = c("fuck","whore","fuckin","motherfuckin","motherfuck","fucker",
          "bitch","shit","bastard","asshol","ass","dick","pussi","cock",
          "crap","cunt")
curseIndex = match(curse,topWords[[1]])

#add "CursePct", percent of words that are curse words
curseIndex = c(261,1895,1205,4648,1749,3524,729,455,2326,4066,874,1851,2638,2871,4697,4513)
totalWords = rowSums(lyrics[,5:5004])
totalCurse = rowSums(lyrics[,(curseIndex+4)])
lyrics$CursePct = totalCurse/totalWords
lyrics <- lyrics[,c(1:4,5005,5006,5:5004)]

###############################
##   begin analysis   #########
###############################
#take small sample
set.seed(5)
train = sample(9469,9469*0.8)
trainDat = lyrics2[train,]

#try to deal with umbalance by oversampling genres w/ songs<200, undersampling genres>500
samplenum = count(trainDat,"Genre")
for(i in 1:15){
  if(samplenum[i,2]>500){samplenum[i,2]=500}
  if(samplenum[i,2]<200){samplenum[i,2]=200}
}
gp = ddply(trainDat,.(Genre), replace = T, function(x) x[sample(nrow(x),samplenum$freq)])
trainDat = gp

#weight vector to reduce rock classification
weight = rep(1,15)
weight[14] = 1/2
names(weight) = genreNames

##logistic with liblinear's heuristic C
##found that in general 0.001 works slightly better than the C though
#C = heuristicC(as.matrix(trainDat[,5:5006]))
train.svm <-LiblineaR(trainDat[,5:5006],trainDat[,2],cost = 0.001, bias=1, type = 0,wi = weight)
pred = predict(train.svm,lyrics2[-train,5:5006])
mse = rep(1,length(pred$predictions))
mse[which(pred$predictions==lyrics2[-train,2])]=0
mean(mse)

#create confusion matrix
cm = confusionMatrix(pred$predictions,lyrics2[-train,2])
cmm = as.matrix(cm)
cmm = cmm %*% diag(1/colSums(cmm))
cmm = data.frame(cmm)
colnames(cmm) = genreNames
cmm$Predicted = genreNames
cmm.m <- melt(cmm)
ggplot(cmm.m, aes(variable, Predicted)) + 
  geom_tile(aes(fill = value),colour = "white") +  
  scale_fill_gradient2(low="#006400", mid="#f2f6c3",high="#cd0000",midpoint=0.3) +
  labs(x = "Actual") +
  theme(axis.text.x = element_text(angle = 60, hjust = 1))