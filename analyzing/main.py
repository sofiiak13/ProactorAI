#
# Title: main.py
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-06-04
# Description: Perl scripts -> training database -> grabber -> pruner -> trainer -> tester


from Grabber import Grabber 
from KNN import KNN

    
database_dir = "/anonymized/file/path"
dataset_name = "2023-1-1_2023-12-31"
sample_len = 14  
# k_range = 400
k = 173
weight = 3

print("Grabbing samples...")
grabber = Grabber(database_dir, sample_len)

print("Writing to datasets...")
grabber.samples_to_file(dataset_name)

print("===Datasets updated===\n")
  

print("Preparing KNN...")
knn = KNN(database_dir, dataset_name, weight)

# test_sample = [0,0,0.30119581464872963,0.18518518518518517,0.05747922437673131,0.1919191919191919,0.020954388509705366,0.005841760265224129]
# result = knn.predict(test_sample, 289)
# print("Is healthy", result)

# print("Weight =", knn.weight, "Determining most-correct k values for samples in validation set...")
# knn.pick_k(1, 500, k_range, 'validation_v0.1_2023-1-1_2023-12-31')   

# print("Finding best k value from correct count file...")
# knn.read_k_file(1, 5)

print("Testing accuracy/precision/recall...")
knn.test_quality(k)