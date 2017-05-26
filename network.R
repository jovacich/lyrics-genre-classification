library(statnet)
############
## creates a network diagram of genre relationships. edges are labeled with a "popular" 
## artist that exemplifies those two genres. the "network" object is created about halfway through the
## consolidation file.

##first create list of edge labels
i = 1
gSort = genreCounts[sort(genreCounts$sum,decreasing = T,index.return=T)$ix,]
for(i in 1:15){
  print(i)
  for(j in 1:15){
    if(j>=i){
      a[15*(i-1)+j]=0
    }
    else{
      b = gSort[with(gSort, which(maxGenre %in% genreNames[c(i,j)])),]
      b = b[which(b[,i]!=0 & b[,j]!=0),]
      b$diff = b[,i]/b[,j]
      b$diff2 = 1/b$diff
      b$diff = apply(b[,20:21],1,min)
      b = b[sort(b$diff,index.return=T,decreasing=T)$ix,]
      a[15*(i-1)+j]=rownames(b)[which.max(c(b[1:ceiling(nrow(b)/1.5),]$sum*b[1:ceiling(nrow(b)/1.5),]$diff,0))]
      print(a[15*(i-1)+j])
    }
  }
}

##manipulate network to get list of significant genre relationships, with weights (mnetwork)
##size is determined by how many songs are in that genre (by artists classified as that genre)
size = network[,17]
mnetwork = as.matrix(network[,2:16])
sum = rowSums(mnetwork)
mnetwork = mnetwork*(100*purity$purity/sum)

lm = t(mnetwork)[which(upper.tri(t(mnetwork))==T)]
um = mnetwork[which(upper.tri(mnetwork)==T)]
um = um+lm
mnetwork[which(upper.tri(mnetwork))]=um
mnetwork[which(lower.tri(mnetwork,diag=T))]=0
mnetwork = as.matrix(mnetwork)
mnetwork[15,]=0
weight = as.list(mnetwork)
weight[which(weight<1)]=0
a=a[which(weight!=0)]
mnetwork = matrix(weight,nrow=15)
colnames(mnetwork) = genreNames
rownames(mnetwork) = genreNames

#create network object with size/weight attributes
mnetwork = as.network(mnetwork,matrix.type="adjacency")
set.vertex.attribute(mnetwork,"Size",size)
set.edge.value(mnetwork,"Weight",weight)

#plot it! kinda messy...
edge.lwd = (get.edge.value(mnetwork,"Weight"))
ggnet2(mnetwork, edge.size = sqrt(edge.lwd)/2.5,label=T,size = unlist(sqrt(size)),
       max_size = 19,color="steelblue",label.size = 3.5, edge.color = "gray50",
       edge.label = a, edge.label.size = 2.8, edge.label.fill = "gray8",
       label.color = "white", edge.alpha = 0.9) + guides(size=FALSE) +
  theme(panel.background = element_rect(fill = "grey8"))
get.edge.value(mnetwork,"Weight")
