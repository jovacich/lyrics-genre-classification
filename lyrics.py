import csv
import numpy

#open test (musiXmatch) data as data
with open("mxm_dataset_test.txt") as f:
    data = f.readlines()
data = [x.strip() for x in data]

#open train data as data2
with open("mxm_dataset_train.txt") as f:
    data2 = f.readlines()
data2 = [x.strip() for x in data2]

#combine
data.extend(data2)
print len(data)
total = len(data)
print "Combined data"

#initialize big matrix
matrix = numpy.zeros((total,5001))
print "Initialized matrix"



#populate big matrix, total terms
for i in range(total):
    data[i] = data[i].split(",")
    for j in range(len(data[i])):
        if j > 1:
            index = data[i][j].split(":")
            index[0] = int(index[0])
            index[1] = int(index[1])
            matrix[i][index[0]-1]=index[1]
    matrix[i][5000] = len(data[i])
print "Matrix Populated"

#send to csv
with open("output.csv", "wb") as f:
    writer = csv.writer(f)
    writer.writerows(matrix)