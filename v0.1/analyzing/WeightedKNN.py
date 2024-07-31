#
# Title: WeightedKNN.py
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-06-18
# Description: performs wighted distance KNN algorithm
#

from math import sqrt
import csv

class WeightedKNN:
    def __init__(self, database_dir, dataset_name):
        self.database_dir = database_dir
        self.dataset_name = dataset_name

        self.weight = 1
        self.dataset = self.file_to_dataset()

    def file_to_dataset(self) -> list:
        """read from csv file and return this data as a list"""

        path = self.database_dir + "/training/training_" + self.dataset_name + ".csv"
        dataset = []
        healthy_count = 0
        unhealthy_count = 0

        with open(path, 'r', newline='') as file:
            reader = csv.reader(file)

            for row in reader:

                sample = [float(val) for val in row]

                if sample[0] == 1:
                    healthy_count += 1
                else:
                    unhealthy_count += 1

                dataset.append(sample)

        return dataset 
    
    def distance(self, sample1, sample2):
        """calculates and returns euclidean distance between sample1 and sample 2"""

        sum = 0.0
        i = 2
        while i < len(sample1):
            sum += (sample1[i] - sample2[i])**2
            i += 1
        return sqrt(sum)
    

    def get_nn(self, test_sample, k):
        """gets and returna list of k nearest neighbours and their distances to the test sample"""

        # get all neighbours
        distances = list()
        for train_sample in self.dataset:
            dist = self.distance(test_sample, train_sample)
            distances.append((train_sample, dist))
            distances.sort(key=lambda tup: tup[1])
            nn = list()
            
        for i in range(k):
            nn.append(distances[i])                         # nn is as list of tuples (neighbour, distance)

        return nn 
    
    def predict(self, test_sample, k):
        """performs weighted knn algorigthm with k value on test_sample and 
        returns 0 for unhealthy sample or 1 for healthy sample"""

        nn = self.get_nn(test_sample, k)

        healthy_sum = 0
        unhealthy_sum = 0

        for n_sample in nn:
            vote = n_sample[0][0]
            if (n_sample[1] == 0):
                dist = 1
            else:
                dist = n_sample[1]

            if vote == 1:
                healthy_sum += (1/dist)
            else:
                unhealthy_sum += (1/dist)

        if healthy_sum > unhealthy_sum:
            return 1
        else:
            return 0
        

    def pick_k(self, start, end, validation_set):
        path = self.database_dir + "/training/" + validation_set + ".csv"
        validation = []
        start = start-1
        end = end-1
        
        with open(path, 'r', newline='') as file:
            reader = csv.reader(file)
            for row in reader:
                sample = [float(val) for val in row]
                validation.append(sample)
                
        correct_counts = [0]*300

        for i, sample in enumerate(validation):

            if (i < start):
                i += 1
                continue

            if (i > end):
                break

            print("...Comparing k options on sample", (i + 1), "...")

            false_positives = 0
            false_negatives = 0

            # get 300 nearest neighbors
            nn = self.get_nn(sample, 300)

            # gather their votes
            nn_distances = [0]*300

            for index, n_sample in enumerate(nn):
                vote = n_sample[0][0]
                dist = n_sample[1]
                nn_distances[index] = (vote, dist)


            # see who wins at different thresholds
            for k in range(0, 300):

                healthy_freq = 0
                unhealthy_freq = 0

                j = 0
                while j < (k + 1):
                    vote = nn_distances[j][0]
                    if (nn_distances[j][1] == 0):
                        dist = 1
                    else:
                        dist = nn_distances[j][1] 

                    if vote == 1:
                        healthy_freq += (1 / dist)
                    else:
                        unhealthy_freq += (1 / dist)
                    j += 1

                if healthy_freq > unhealthy_freq:     # k value guessed healthy
                    if sample[0] == 1:
                        correct_counts[k] += 1
                        #print("Correct healthy at k = ", k + 1, " for sample ", i)
                    else:
                        #print("False negative at k = ", k + 1, " for sample ", i)
                        false_negatives += 1
                        pass
                else:                               # k value guessed unhealthy
                    if sample[0] == 0:
                        correct_counts[k] += 1
                        #print("Correct unhealthy at k = ", k + 1, " for sample ", i)
                    else:
                        #print("False positive at k = ", k + 1, " for sample ", i)
                        false_positives += 1
                        pass
            i += 1
            print("False positive count: ", false_positives, "False negative count: ", false_negatives)

        filename = "k_correct_counts_weighted.csv"
    
        with open(filename, mode='a', newline='') as file:
            writer = csv.writer(file)
            writer.writerow([f"Samples {start+1}-{end+1} Inclusive"] + correct_counts)

        return
    

    def read_k_file(self, start, end):
        """read from the csv file to determine which k has the highest correct count"""
        start = start-1
        end = end-1

        totals = [0]*300

        with open('k_correct_counts_weighted.csv', 'r') as file:
            reader = csv.reader(file)

            for i, row in enumerate(reader):
                if i < start:
                    continue
                if i > end:
                    break

                values = list(map(int, row[1:]))

                for i, value in enumerate(values):
                    totals[i] += value
        
        most_correct = max(totals)
        best_k = totals.index(most_correct) + 1

        print("Best k value was ", best_k, " with ", most_correct, " correct.")

        return
    
