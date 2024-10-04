# Anonymized version of ProactorAI
Rem D'Ambrosio and I developed this program under the supervision of Tariq Chatur during the Summer 2024 Co-op term at BCPS. 
### v0.0
The script pulls some device information from various large-scale APIs, sorts and stores appropriately. 
Then, it analyzes "health" of all devices at a site and creates a report with sites that are not 100% healthy. An example of the report appears in output.txt file.
This version 0.0 is written fully in Perl and it does not use any AI algorithms.

### v0.1

The script pulls historical information over a year period about all the devices in order to populate a dataset for trainig and validation. 
In this version, we use KNN for the binary classification of healthy and unhealthy devices (switches).
In order to find best k, we efficiently try different values in some specified range. 
Due to the number of healthy devices outweighing unhealthy devices, we also tried using weights with KNN. It is available under WeightedKNN.py.
This version 0.1 is written in Perl and Python and it uses a Machine Learning algorithm (KNN) for analysis.

### v0.2

Version 0.2 pulls information and stores it in device objects the same way version v0.1 does, however analyzing part is different. In this version, we use Regular Neural Networks in order to identify which device is failing and which one is healthy. We also try comparing BCE VS BCEWithLogits, drop out VS no drop out etc. 
