# Title: Tester.py
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-07-18

import os
import torch  
import torch.nn as nn
import torch.optim as optim
import pandas as pd
import numpy as np
from torch.utils.data import DataLoader, TensorDataset
from NeuralNetwork import NeuralNetwork

class Tester(): 
    def __init__(self, data_path):
        self.data_path = data_path + "/training/validation_v0.2_2023-1-1_2024-8-1.csv" 
        self.device = 'cuda' if torch.cuda.is_available() else 'cpu' 
        self.parameters = ['temp_avg', 'temp_avg_stdev', 'temp_avg_slope',
                            'temp_max', 'temp_max_stdev', 'temp_max_slope',
                            'cpu_avg', 'cpu_avg_stdev', 'cpu_avg_slope',
                            'cpu_max', 'cpu_max_stdev', 'cpu_max_slope',
                            'latency_avg', 'latency_avg_stdev', 'latency_avg_slope',
                            'latency_max', 'latency_max_stdev', 'latency_max_slope']
        self.threshold = 0.2
        self.data = self.to_dataframe()


    def test_model(self, model): 
        inputs = self.parameters
        x = torch.tensor(self.data[inputs].values,dtype=torch.float)
        outputs = ['failing', 'row']
        y = torch.tensor(self.data[outputs].values,dtype=torch.float)
 
        dataset = TensorDataset(x, y)
        batch_size =  1000
        test_loader = DataLoader(dataset, batch_size=batch_size, shuffle=True)
        model.to(self.device)                           # Move model to either the CPU or GPU 
        pos_weight = torch.tensor([0.03])
        criterion = torch.nn.BCEWithLogitsLoss(pos_weight=pos_weight)        # Measure our neural network by binary cross-entropy loss

        total_loss = 0.0
        true_positive = 0  
        false_positive = 0
        false_negative = 0
        true_negative = 0

        with torch.no_grad():                                   # Disable gradient calculation
            i = 0
            for batch_x, batch_y in test_loader:
                batch_x, batch_y = batch_x.to(self.device), batch_y.to(self.device)
                y_pred = model(batch_x)
                y_actual = batch_y[:,0].unsqueeze(1)
                y_rows = batch_y[:,1]
                
                loss = criterion(y_pred, y_actual)                 # Measure how well the model predicted vs actual
                total_loss += loss.item()                          # Track how well the model predict

                #y_pred_binary = (y_pred > self.threshold).cpu().detach().numpy()   # Convert predictions and actuals to binary
                #y_actual_binary = y_actual.cpu().detach().numpy()
                
                y_pred_binary = (torch.sigmoid(y_pred) > self.threshold).float().cpu().detach().numpy()
                y_actual_binary = y_actual.cpu().detach().numpy()
                

                # self.print_correct_pred(y_actual, y_rows, y_pred_binary, 0, i)

                true_positive += ((y_pred_binary == 1) & (y_actual_binary == 1)).sum()
                false_positive += ((y_pred_binary == 1) & (y_actual_binary == 0)).sum()
                false_negative += ((y_pred_binary == 0) & (y_actual_binary == 1)).sum()
                true_negative += ((y_pred_binary == 0) & (y_actual_binary == 0)).sum()

                i += 1

        accuracy = (true_positive + true_negative) / (true_positive + true_negative + false_positive + false_negative) 
        precision = true_positive / (true_positive + false_positive) if (true_positive + false_positive) > 0 else 0
        recall = true_positive / (true_positive + false_negative) if (true_positive + false_negative) > 0 else 0
        f1_score = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0

        print(f"=== RESULTS at Threshold = {self.threshold} ===")
        print(f"Total Loss: {total_loss}")
        print(f"Accuracy: {accuracy:.4f}, Precision: {precision:.4f}, Recall: {recall:.4f}, F1 Score: {f1_score:.4f}")
        print(f"True Positive: {true_positive}, False Positive: {false_positive}, True Negative: {true_negative}, False Negative: {false_negative}")


    def print_correct_pred(self, y_actual, y_rows, y_pred_binary, model_num, batch_num):

        y_actual_df = pd.DataFrame(y_actual.numpy().astype(int))  
        y_pred_df = pd.DataFrame(y_pred_binary.astype(int))
        y_rows_df = pd.DataFrame(y_rows.numpy().astype(str))
        
        comparison_df = pd.concat([y_rows_df, y_actual_df, y_pred_df], axis=1)
        comparison_df.columns = ['Row', 'Actual', 'Prediction']
        filtered_df = comparison_df[(comparison_df['Actual'] == 1) & (comparison_df['Prediction'] == 1)]        # true positives
        
        if not filtered_df.empty:
            print("For model", model_num+1, "in batch", batch_num+1, "\n", filtered_df.to_string(index=False))


    def test_ensemble(self, models):
        inputs = self.parameters
        x = torch.tensor(self.data[inputs].values,dtype=torch.float)
        outputs = ['failing', 'row']
        y = torch.tensor(self.data[outputs].values,dtype=torch.float)

        dataset = TensorDataset(x, y)
        batch_size = 1000
        test_loader = DataLoader(dataset, batch_size=batch_size, shuffle=True)

        for model in models:
            model.to(self.device)

        #criterion = torch.nn.BCELoss()
        pos_weight = torch.tensor([0.03])
        criterion = torch.nn.BCEWithLogitsLoss(pos_weight=pos_weight)

        total_loss = 0.0
        true_positive = 0  
        false_positive = 0
        false_negative = 0
        true_negative = 0

        with torch.no_grad():
            i = 0
            for batch_x, batch_y in test_loader:
                i += 1
                batch_x, batch_y = batch_x.to(self.device), batch_y.to(self.device)

                votes = torch.empty((len(batch_x), 0), dtype=torch.bool)

                for j, model in enumerate(models):
                    y_pred = model(batch_x)
                    y_actual = batch_y[:,0].unsqueeze(1)
                    y_rows = batch_y[:,1]
                    
                    loss = criterion(y_pred, y_actual)                 # Measure how well the model predicted vs actual
                    total_loss += loss.item()                          # Track how well the model predict

                    y_pred_binary = (torch.sigmoid(y_pred) > self.threshold)
                    y_actual_binary = y_actual.cpu().detach().numpy()

                    votes = torch.cat((votes, y_pred_binary), dim=1).int()

                    # self.print_correct_pred(y_actual, y_rows, y_pred_binary, j, i)
                 
                decisions, _ = torch.mode(votes, dim=1)
                decisions = decisions.unsqueeze(1)
                y_pred_voted = decisions.cpu().detach().numpy().astype(int)
                y_actual_binary = y_actual.cpu().detach().numpy().astype(int)
               
                true_positive += ((y_pred_voted == 1) & (y_actual_binary == 1)).sum()
                false_positive += ((y_pred_voted == 1) & (y_actual_binary == 0)).sum()
                false_negative += ((y_pred_voted == 0) & (y_actual_binary == 1)).sum()
                true_negative += ((y_pred_voted == 0) & (y_actual_binary == 0)).sum()

        accuracy = (true_positive + true_negative) / (true_positive + true_negative + false_positive + false_negative)
        precision = true_positive / (true_positive + false_positive) if (true_positive + false_positive) > 0 else 0
        recall = true_positive / (true_positive + false_negative) if (true_positive + false_negative) > 0 else 0
        f1_score = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0

        total_loss = total_loss / len(models)

        print(f"=== RESULTS at Threshold = {self.threshold} ===")
        print(f"Total Loss: {total_loss}")
        print(f"Accuracy: {accuracy:.4f}, Precision: {precision:.4f}, Recall: {recall:.4f}, F1 Score: {f1_score:.4f}")
        print(f"True Positive: {true_positive}, False Positive: {false_positive}, True Negative: {true_negative}, False Negative: {false_negative}")


# ========================================================================================================================================================
# I/O FUNCTIONS
# ========================================================================================================================================================
 

    def to_dataframe(self):
        columns = ['failing', 'model'] + self.parameters + ['name']
        df = pd.read_csv(self.data_path, names=columns)
        df['row'] = df.index + 1
        return df  


    def load_model(self, model_path):
        ''' Loads trained NeuralNetwork model from file 
            Parameters:     path: str, path to the model file
            Returns:        model: NeuralNetwork object'''
        
        model = NeuralNetwork()                           # create empty model
        model.load_state_dict(torch.load(model_path))     # load a static dict with trained parameters from file to the model
        model.eval()                                      # set model to evaluation mode
        return model
 
 
    def load_ensemble(self, ensemble_path):
        models = []
        model_filenames = [f for f in os.listdir(ensemble_path) if os.path.isfile(os.path.join(ensemble_path, f))]
        model_filenames.sort()
        for filename in model_filenames:
            print(filename)
            path = ensemble_path + filename
            model = NeuralNetwork()                         # create empty model
            model.load_state_dict(torch.load(path))         # load a static dict with trained parameters from file to the model
            model.eval()                                    # set model to evaluation mode
            models.append(model)
        return models