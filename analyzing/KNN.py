#
# Title: KNN.py
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-06-18
# Description: perfoming K nearest neighbours algorithm
#

from math import sqrt
import csv
import re


class KNN:
    def __init__(self, database_dir, dataset_name, weight = 1):
        self.database_dir = database_dir
        self.dataset_name = dataset_name

        self.weight = weight
        self.dataset = self.file_to_dataset()

    def file_to_dataset(self) -> list:
        """read from csv file and return this data as a list"""

        path = self.database_dir + "/training/training_" + self.dataset_name + ".csv"
        dataset = []
        healthy_count = 0
        unhealthy_count = 0

        # training_size = 10000

        with open(path, 'r', newline='') as file:
            reader = csv.reader(file)

            for i, row in enumerate(reader):
                # if i >= training_size:
                #     break

                sample = [float(val) for val in row]

                if sample[0] == 1:
                    healthy_count += 1
                else:
                    unhealthy_count += 1

                dataset.append(sample)

        return dataset 


    def predict(self, test_sample, k):
        """performs KNN algorigthm with k value on test_sample """

        nn = self.get_nn(test_sample, k)

        healthy_sum = 0
        unhealthy_sum = 0

        for n_sample in nn:
            vote = n_sample[0]

            if vote == 1:
                healthy_sum += 1
            else:
                unhealthy_sum += 1

        if (self.weight * healthy_sum) > unhealthy_sum:
            return 1
        else:
            return 0
        
        
    def get_nn(self, test_sample, k):
        """gets a list of k nearest neighbours to the test sample"""

        distances = list()
        for train_sample in self.dataset:
            dist = self.distance(test_sample, train_sample)
            distances.append((train_sample, dist))
            distances.sort(key=lambda tup: tup[1])
            nn = list()
            
        for i in range(k):
            nn.append(distances[i][0])
            
        return nn
   
    def distance(self, sample1, sample2):
        """calculates and returns euclidean distance between sample1 and sample 2"""
        sum = 0.0
        i = 2
        while i < len(sample1):
            sum += (sample1[i] - sample2[i])**2
            i += 1
        return sqrt(sum)
        
   
    def pick_k(self, start, end, k_range, validation_set):
        
        path = self.database_dir + "/training/" + validation_set + ".csv"

        start = start-1
        end = end-1

        validation = []
        with open(path, 'r', newline='') as file:
            reader = csv.reader(file)
            for row in reader:
                sample = [float(val) for val in row]
                validation.append(sample)
        
        true_positives = [0]*k_range
        true_negatives = [0]*k_range
        false_positives = [0]*k_range
        false_negatives = [0]*k_range
        total_samples = end - start + 1

        for i, sample in enumerate(validation):

            if (i < start):
                continue

            if (i > end):
                break

            print("...Comparing k options on sample", (i + 1), "...")

            # get k_range nearest neighbors
            nn = self.get_nn(sample, k_range)

            # gather their votes
            votes = [0]*k_range
            for index, n_sample in enumerate(nn):
                vote = n_sample[0]
                if vote == 1:
                    votes[index] = 1
                else:
                    votes[index] = 0

            # see who wins at different thresholds
            for k in range(0, k_range):

                healthy_sum = 0
                unhealthy_sum = 0

                j = 0
                while j < (k + 1):  
                    vote = votes[j]
                    if vote == 1:
                        healthy_sum += 1
                    else:
                        unhealthy_sum += 1
                    j += 1

                if( self.weight * healthy_sum) > unhealthy_sum:     # that k value guessed healthy
                    if sample[0] == 1:
                        true_negatives[k] += 1
                    else:
                        false_negatives[k] += 1
                else:                               # that k value guessed unhealthy
                    if sample[0] == 0:
                        true_positives[k] += 1
                    else:
                        false_positives[k] += 1

        self.results_to_file(true_positives, true_negatives, false_positives, false_negatives, (start+1), (end+1))

        return

    def results_to_file(self, true_positives, true_negatives, false_positives, false_negatives, start, end):
        """writes the sum of all true positive, true negative, false positive and false negative values
           that we received after testing multiple k to the file"""
        
        filename = "k_testing/k_results_w" + str(self.weight) + ".csv"

    
        with open(filename, mode='a', newline='') as file:
            writer = csv.writer(file)
            writer.writerow([f"Samples {start}-{end} Inclusive: TP"] + true_positives)
            writer.writerow([f"Samples {start}-{end} Inclusive: TN"] + true_negatives)
            writer.writerow([f"Samples {start}-{end} Inclusive: FP"] + false_positives)
            writer.writerow([f"Samples {start}-{end} Inclusive: FN"] + false_negatives)

        print("Done writing results to file.")

        return


    def calculate_performance(self, true_positives, true_negatives, false_positives, false_negatives, total_samples, k_range):
        """calculates performance values (precision, recall, accuracy, f1) for all tested k values
           and prints the best k and best result to the console"""
        best_accuracy = 0
        best_a_k = 0
        best_precision = 0
        best_p_k = 0
        best_recall = 0
        best_r_k = 0
        best_f1 = 0
        best_f_k = 0
        
        for i in range(k_range):
            accuracy = (true_positives[i] + true_negatives[i]) / total_samples

            if true_positives[i] == 0 and false_positives[i] == 0:
                precision = None
            else:
                precision = true_positives[i] / (true_positives[i] + false_positives[i])

            if true_positives[i] == 0 and false_negatives[i] == 0:
                recall = None
            else:
                recall = true_positives[i] / (true_positives[i] + false_negatives[i])

            if precision and recall:
                f1 = 2 * ((precision * recall) / (precision + recall))
            else:
                f1 = None
            
            if (accuracy > best_accuracy):
                best_accuracy = accuracy
                best_a_k = i+1
            if precision and (precision > best_precision):
                best_precision = precision
                best_p_k = i+1
            if recall and (recall > best_recall):
                best_recall = recall
                best_r_k = i+1
            if f1 and (f1 > best_f1):
                best_f1 = f1
                best_f_k = i+1
            
        print(f"""
        Best k for accuracy was {best_a_k} with {best_accuracy}
        Best k for precision was {best_p_k} with {best_precision}
        Best k for recall was {best_r_k} with {best_recall}
        Best k for F1 was {best_f_k} with {best_f1}
        Per {total_samples} total samples""")


    def read_results(self, filepath, k_range):
        """reads from csv file at filepath, stores all the values (TP, TN, FP, FN) to 4 separate lists and 
        returns them and number of total samples """
        true_positives = [0]*k_range
        true_negatives = [0]*k_range
        false_positives = [0]*k_range
        false_negatives = [0]*k_range
        total_samples = 0
        
        with open(filepath, 'r') as file:
            reader = csv.reader(file)

            for i, row in enumerate(reader):
                # if i > 4:
                #     break

                details = row[0]
                first_sample = int(re.findall("(\d+)-",details)[0])
                last_sample = int(re.findall("-(\d+)",details)[0])
                
                values = list(map(int, row[1:]))
                if "TP" in details:
                    for i in range(k_range):
                        true_positives[i] += values[i] 
                    total_samples += last_sample - first_sample + 1             # total samples is updated once per four lines
                elif "TN" in details:
                    for i in range(k_range):
                        true_negatives[i] += values[i] 
                elif "FP" in details:
                    for i in range(k_range):
                        false_positives[i] += values[i] 
                elif "FN" in details:
                    for i in range(k_range):
                        false_negatives[i] += values[i] 

        return true_positives, true_negatives, false_positives, false_negatives, total_samples

  
    def read_k_file(self, start, end):
        """read from the csv file to determine which k has the highest correct count"""

        start = start-1
        end = end-1

        totals = [0]*400

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
    
    def test_quality(self, k):

        true_positives, true_negatives, false_positives, false_negatives, total_samples = self.read_results("k_testing/k_results_w4.csv", 400)
        print("For ", k)
        accuracy = (true_positives[k] + true_negatives[k]) / total_samples
        precision = true_positives[k] / (true_positives[k] + false_positives[k])
        recall = true_positives[k] / (true_positives[k] + false_negatives[k])
        f1 = 2 * ((precision * recall) / (precision + recall))

        print(f"""Accuracy is {accuracy}
                Precision is {precision}
                Recall is {recall}
                F1 is {f1}
                Per {total_samples} total samples""")
        
        print("There were", true_positives[k], "true positives")
        print("There were", false_negatives[k], "false negatives")
